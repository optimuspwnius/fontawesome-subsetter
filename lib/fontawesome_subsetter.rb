require_relative "fontawesome_subsetter/version"
require_relative "fontawesome_subsetter/icon_helper"
require_relative "fontawesome_subsetter/subsetter"
require_relative "fontawesome_subsetter/engine" if defined?(Rails)

module FontawesomeSubsetter

  class << self

    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

  end

  class Configuration

    attr_accessor :meta_path, :fonts_dir, :build_dir, :scan_globs, :watch_paths,
                  :watch_file_type_regex, :icon_regex, :scss_template, :styles

    def initialize
      @scan_globs = ["app/views/**/*.slim", "app/helpers/**/*.rb"]
      @watch_file_type_regex = /\.(slim|rb)$/
      @icon_regex = /icon\(\s*:(?<prefix>fas|far|fab|fad|fal|fat)\s*,\s*:(?<icon>[\w_\-]+)\b/
    end

  end

end
