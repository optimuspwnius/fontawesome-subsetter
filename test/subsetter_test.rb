require "test_helper"
require "tmpdir"
require "fileutils"
require "pathname"

class SubsetterTest < Minitest::Test

  FIXTURES = File.expand_path("fixtures", __dir__)

  def setup
    FontawesomeSubsetter.configuration = nil

    @tmpdir = Dir.mktmpdir("fa_subsetter_test")
    @build_dir = File.join(@tmpdir, "builds")
    FileUtils.mkdir_p(@build_dir)

    FontawesomeSubsetter.configure do |config|
      config.meta_path  = Pathname.new(File.join(FIXTURES, "metadata", "icons.yml"))
      config.fonts_dir  = Pathname.new(File.join(FIXTURES, "webfonts"))
      config.build_dir  = Pathname.new(@build_dir)
      config.scan_globs = [File.join(FIXTURES, "views", "*.slim")]
    end

    @subsetter = FontawesomeSubsetter::Subsetter.new(root: @tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    FontawesomeSubsetter.configuration = nil
  end

  # --- Initialization ---

  def test_creates_webfonts_directory
    webfonts_dir = File.join(@build_dir, "webfonts")
    assert Dir.exist?(webfonts_dir)
  end

  # --- scan_files_and_update_caches ---

  def test_scan_detects_solid_icons
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    solid = style_by_prefix("fas")
    assert_includes solid[:icon_cache], "home"
    assert_includes solid[:icon_cache], "arrow-left"
  end

  def test_scan_detects_regular_icons
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    regular = style_by_prefix("far")
    assert_includes regular[:icon_cache], "star"
  end

  def test_scan_detects_brands_icons
    files = [File.join(FIXTURES, "views", "other.slim")]
    @subsetter.scan_files_and_update_caches(files)

    brands = style_by_prefix("fab")
    assert_includes brands[:icon_cache], "github"
  end

  def test_scan_detects_duotone_icons
    files = [File.join(FIXTURES, "views", "other.slim")]
    @subsetter.scan_files_and_update_caches(files)

    duotone = style_by_prefix("fad")
    assert_includes duotone[:icon_cache], "spinner"
  end

  def test_scan_detects_light_icons
    files = [File.join(FIXTURES, "views", "other.slim")]
    @subsetter.scan_files_and_update_caches(files)

    light = style_by_prefix("fal")
    assert_includes light[:icon_cache], "check"
  end

  def test_scan_populates_unicode_cache
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    solid = style_by_prefix("fas")
    assert_includes solid[:unicode_cache], "U+F015"  # home
    assert_includes solid[:unicode_cache], "U+10F015" # home secondary
    assert_includes solid[:unicode_cache], "U+F060"  # arrow-left
  end

  def test_scan_populates_sass_icon_cache
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    solid = style_by_prefix("fas")
    assert solid[:sass_icon_cache].any? { |entry| entry.include?("home") }
    assert solid[:sass_icon_cache].any? { |entry| entry.include?("arrow-left") }
  end

  def test_scan_marks_style_changed
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    solid = style_by_prefix("fas")
    assert solid[:changed], "solid style should be marked as changed"

    regular = style_by_prefix("far")
    assert regular[:changed], "regular style should be marked as changed"
  end

  def test_scan_unchanged_styles_not_marked
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    # sample.slim has no brands icons
    brands = style_by_prefix("fab")
    refute brands[:changed], "brands style should not be marked as changed"
  end

  def test_scan_duplicate_icon_not_marked_changed_twice
    files = [File.join(FIXTURES, "views", "sample.slim")]
    @subsetter.scan_files_and_update_caches(files)

    solid = style_by_prefix("fas")
    solid[:changed] = false

    # Scanning the same files again should not re-mark as changed
    @subsetter.scan_files_and_update_caches(files)
    refute solid[:changed], "style should not be marked changed when icons already cached"
  end

  def test_scan_multiple_files
    files = Dir.glob(File.join(FIXTURES, "views", "*.slim"))
    @subsetter.scan_files_and_update_caches(files)

    solid   = style_by_prefix("fas")
    regular = style_by_prefix("far")
    brands  = style_by_prefix("fab")
    duotone = style_by_prefix("fad")
    light   = style_by_prefix("fal")

    assert_includes solid[:icon_cache], "home"
    assert_includes solid[:icon_cache], "arrow-left"
    assert_includes regular[:icon_cache], "star"
    assert_includes brands[:icon_cache], "github"
    assert_includes duotone[:icon_cache], "spinner"
    assert_includes light[:icon_cache], "check"
  end

  def test_scan_with_underscored_icon_name
    # The icon_regex matches underscored names; subsetter normalizes to dashes
    file = write_temp_view('= icon(:fas, :arrow_left)')
    @subsetter.scan_files_and_update_caches([file])

    solid = style_by_prefix("fas")
    assert_includes solid[:icon_cache], "arrow-left"
  end

  def test_scan_ignores_unknown_icons
    file = write_temp_view('= icon(:fas, :nonexistent_icon)')
    @subsetter.scan_files_and_update_caches([file])

    solid = style_by_prefix("fas")
    refute_includes solid[:icon_cache], "nonexistent-icon"
  end

  def test_scan_resolves_alias_names
    # "house" is an alias for "home" in our fixture metadata
    file = write_temp_view('= icon(:fas, :house)')
    @subsetter.scan_files_and_update_caches([file])

    solid = style_by_prefix("fas")
    assert_includes solid[:icon_cache], "house"
    assert_includes solid[:unicode_cache], "U+F015"
  end

  def test_scan_resolves_loading_alias
    # "loading" is an alias for "spinner" in fixtures
    file = write_temp_view('= icon(:fad, :loading)')
    @subsetter.scan_files_and_update_caches([file])

    duotone = style_by_prefix("fad")
    assert_includes duotone[:icon_cache], "loading"
  end

  def test_scan_empty_file
    file = write_temp_view("")
    @subsetter.scan_files_and_update_caches([file])

    all_unchanged = styles.all? { |s| !s[:changed] }
    assert all_unchanged, "no styles should be changed for an empty file"
  end

  def test_scan_file_with_no_icons
    file = write_temp_view("h1 Hello World\np This is a paragraph")
    @subsetter.scan_files_and_update_caches([file])

    all_unchanged = styles.all? { |s| !s[:changed] }
    assert all_unchanged, "no styles should be changed for a file without icons"
  end

  private

  def style_by_prefix(prefix)
    styles.find { |s| s[:prefix] == prefix }
  end

  def styles
    @subsetter.instance_variable_get(:@styles).values
  end

  def write_temp_view(content)
    path = File.join(@tmpdir, "test_view_#{SecureRandom.hex(4)}.slim")
    File.write(path, content)
    path
  end

end
