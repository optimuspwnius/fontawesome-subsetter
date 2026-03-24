require "json"
require "open3"
require "fileutils"
require "yaml"
require "set"

module FontawesomeSubsetter

  class Subsetter

    def initialize(root: nil)
      @file_icon_map = {}
      @root          = root || defined?(Rails) && Rails.root || Pathname.new(Dir.pwd)
      @root          = Pathname.new(@root) unless @root.is_a?(Pathname)

      config = FontawesomeSubsetter.configuration

      @meta_path  = config.meta_path  || @root.join("vendor", "fontawesome", "metadata", "icons.yml")
      @fonts_dir  = config.fonts_dir  || @root.join("vendor", "fontawesome", "webfonts")
      @build_dir  = config.build_dir  || @root.join("app", "assets", "builds")
      @webfonts_dir = @build_dir.join("webfonts")
      @scan_globs = config.scan_globs
      @icon_regex = config.icon_regex

      @styles = {
        "solid"   => { name: "solid",   prefix: "fas", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-solid-900.woff2"   },
        "regular" => { name: "regular", prefix: "far", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-regular-400.woff2" },
        "light"   => { name: "light",   prefix: "fal", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-thin-100.woff2"    },
        "thin"    => { name: "thin",    prefix: "fat", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-thin-100.woff2"    },
        "duotone" => { name: "duotone", prefix: "fad", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-duotone-900.woff2" },
        "brands"  => { name: "brands",  prefix: "fab", unicode_cache: Set.new, icon_cache: Set.new, sass_icon_cache: Set.new, changed: false, file: "fa-brands-400.woff2"  }
      }

      @watch_paths = [
        @root.join("app", "views"),
        @root.join("app", "helpers"),
        @root.join("app", "components")
      ].select(&:exist?)

      @watch_file_type_regex = config.watch_file_type_regex

      FileUtils.rm_rf(@webfonts_dir)
      FileUtils.mkdir_p(@webfonts_dir)

      # Load FontAwesome metadata
      @metadata = YAML.safe_load(File.read(@meta_path))

      # Build unicode map, set entry to an array of all codepoints (main + secondary)
      @metadata.each { | key, entry | @metadata[key]["unicodes"] = Set.new([ "U+#{ entry['unicode'].upcase }", *entry.dig("aliases", "unicodes", "secondary")&.map { | s | "U+#{ s.upcase }" } ]) }

      # Build alias map
      @metadata.merge!(@metadata.values.flat_map { | entry | (entry.dig("aliases", "names") || []).map { [ it, entry ] } }.to_h)

      # Strip useless metadata
      @metadata.each_value { it.except!("changes", "label", "voted", "search", "styles", "aliases") }
    end

    # Updates the cache for each style, returns the styles that have changed.
    def scan_files_and_update_caches(files)
      files.each do | path |

        text = File.read(path)
        text.scan(@icon_regex).each do | prefix, icon |

          style = @styles.find { it&.last[:prefix] == prefix }&.last
          next unless style

          normalized = icon.tr("_", "-")
          entry = @metadata[normalized]
          next unless entry

          # If the icon is new for this style, update the caches
          if style[:icon_cache].add?(normalized)
            style[:unicode_cache].merge(entry["unicodes"])
            style[:sass_icon_cache].add("\"#{ normalized }\": \\#{ entry['unicode'] }")
            style[:changed] = true
          else
            nil
          end

        end

      end
    end

    # Takes an array of styles and creates a thread to subset each font file
    def subset_webfonts(styles)
      styles.map { | style | Thread.new(style) { subset_font(style) } }.each(&:join)
    end

    def subset_font(style)
      file     = style[:file]
      out_file = @webfonts_dir.join(file)
      cmd      = "pyftsubset #{ @fonts_dir.join(file) } --flavor=woff2 --unicodes=#{ style[:unicode_cache].to_a.join(",") } --output-file=#{ out_file } --layout-features=* --no-hinting"

      puts "[FontSubsetter][#{ style[:name] }] #{ cmd }"
      stdout, stderr, status = Open3.capture3(cmd)
      if status.success?
        puts "[FontSubsetter][#{ style[:name] }] wrote #{ out_file }"
      else
        warn "[FontSubsetter][#{ style[:name] }] subset failed:\n#{ stderr }"
        raise "pyftsubset failed (exit #{ status.exitstatus })"
      end
    end

    def subset_stylesheets
      styles = @styles.values.select { it[:sass_icon_cache].any? }

      scss_template = FontawesomeSubsetter.configuration.scss_template

      scss_string = if scss_template
        scss_template.call(@styles)
      else
        default_scss_template(styles)
      end

      # Compile the dynamic SCSS. `load_paths` tells Sass where to find the imported files.
      compiled_css = Sass.compile_string(scss_string, style: :compressed, load_paths: [ @root ]).css

      # Forcefully remove all comments, including "loud" /*! ... */ comments for licenses.
      compiled_css = compiled_css.gsub(/\/\*!.*?\*\//m, "")

      # Output to builds folder, which is the standard for Propshaft
      out_file = @build_dir.join("fontawesome.css")
      File.write(out_file, compiled_css)
      puts "[FontSubsetter] wrote #{ out_file } with styles: #{ styles.map { it[:name] }.join(', ') }"
    end

    def build(files_to_scan = nil)
      files_to_scan ||= @scan_globs.flat_map { Dir.glob it }

      scan_files_and_update_caches(files_to_scan)

      styles = @styles.values.select { it[:changed] }

      # Rebuild assets only if caches have changed
      unless styles.empty?
        subset_webfonts(styles)
        subset_stylesheets
        @styles.values.each { it[:changed] = false }
      end
    end

    def build_watch
      require "listen"

      # Initial full scan and build
      build()

      puts "Starting FontAwesome watch mode..."

      listener = Listen.to(*@watch_paths) do | modified, added, removed |

        # NOTE: At most, it seems to take around 1.7 seconds to subset
        start_time = Time.now

        puts "Detected changes: modified=#{ modified }, added=#{ added }, removed=#{ removed }"

        # Scan only modified and added files
        build(modified + added)

        elapsed = Time.now - start_time
        puts "[FontSubsetter] Total subsetting time: #{ format('%.2f', elapsed) } seconds"

      end

      listener.start

      # Keep the process alive
      loop do

        sleep 1

      end
    rescue Interrupt
      puts "FontAwesome watch stopped"
      listener&.stop
    end

    private

    def default_scss_template(styles)
      <<-SCSS

        // NOTE: $icons and $brand-icons were changed in variables to just be empty arrays with !default.
        @use "./vendor/fontawesome/scss/variables" with (
          $font-path: "webfonts",
          $icons: (#{ @styles.except("brands").values.reduce(Set.new) { | all_icons, style | all_icons.merge(style[:sass_icon_cache]) }.join(", ") }),
          $brand-icons: (#{ @styles["brands"][:sass_icon_cache].to_a.join(", ") }));

        @use "./vendor/fontawesome/scss/functions";
        @use "./vendor/fontawesome/scss/mixins";
        @use "./vendor/fontawesome/scss/core";
        // @use "./vendor/fontawesome/scss/sizing";
        // @use "./vendor/fontawesome/scss/widths";
        // @use "./vendor/fontawesome/scss/list";
        // @use "./vendor/fontawesome/scss/bordered";
        @use "./vendor/fontawesome/scss/animated";
        // @use "./vendor/fontawesome/scss/rotated-flipped";
        // @use "./vendor/fontawesome/scss/stacked";
        @use "./vendor/fontawesome/scss/icons";

        #{ styles.map { "@use \"./vendor/fontawesome/scss/#{ it[:name] }.scss\";" }.join("\n") }

      SCSS
    end

  end

end
