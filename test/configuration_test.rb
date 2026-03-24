require "test_helper"

class ConfigurationTest < Minitest::Test

  def setup
    FontawesomeSubsetter.configuration = nil
  end

  def test_default_scan_globs
    config = FontawesomeSubsetter.configuration
    assert_equal ["app/views/**/*.slim", "app/helpers/**/*.rb"], config.scan_globs
  end

  def test_default_watch_file_type_regex
    config = FontawesomeSubsetter.configuration
    assert_equal(/\.(slim|rb)$/, config.watch_file_type_regex)
  end

  def test_default_icon_regex_matches_fas
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fas, :arrow_left)')
    assert match
    assert_equal "fas", match[:prefix]
    assert_equal "arrow_left", match[:icon]
  end

  def test_default_icon_regex_matches_far
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:far, :circle)')
    assert match
    assert_equal "far", match[:prefix]
    assert_equal "circle", match[:icon]
  end

  def test_default_icon_regex_matches_fab
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fab, :github)')
    assert match
    assert_equal "fab", match[:prefix]
    assert_equal "github", match[:icon]
  end

  def test_default_icon_regex_matches_fad
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fad, :spinner)')
    assert match
    assert_equal "fad", match[:prefix]
    assert_equal "spinner", match[:icon]
  end

  def test_default_icon_regex_matches_fal
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fal, :check)')
    assert match
    assert_equal "fal", match[:prefix]
    assert_equal "check", match[:icon]
  end

  def test_default_icon_regex_matches_fat
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fat, :star)')
    assert match
    assert_equal "fat", match[:prefix]
    assert_equal "star", match[:icon]
  end

  def test_default_icon_regex_with_spaces
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(  :fas,  :arrow_left  )')
    assert match
    assert_equal "fas", match[:prefix]
    assert_equal "arrow_left", match[:icon]
  end

  def test_default_icon_regex_does_not_match_invalid_prefix
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fax, :something)')
    assert_nil match
  end

  def test_default_icon_regex_matches_hyphenated_names
    config = FontawesomeSubsetter.configuration
    match = config.icon_regex.match('icon(:fas, :arrow-left)')
    assert match
    assert_equal "arrow-left", match[:icon]
  end

  def test_default_meta_path_is_nil
    config = FontawesomeSubsetter.configuration
    assert_nil config.meta_path
  end

  def test_default_fonts_dir_is_nil
    config = FontawesomeSubsetter.configuration
    assert_nil config.fonts_dir
  end

  def test_default_build_dir_is_nil
    config = FontawesomeSubsetter.configuration
    assert_nil config.build_dir
  end

  def test_configure_block
    FontawesomeSubsetter.configure do |config|
      config.scan_globs = ["app/views/**/*.erb"]
    end

    assert_equal ["app/views/**/*.erb"], FontawesomeSubsetter.configuration.scan_globs
  end

  def test_configure_preserves_other_defaults
    FontawesomeSubsetter.configure do |config|
      config.scan_globs = ["custom/**/*.rb"]
    end

    assert_equal(/\.(slim|rb)$/, FontawesomeSubsetter.configuration.watch_file_type_regex)
  end

  def test_configuration_setters
    config = FontawesomeSubsetter.configuration
    config.meta_path = "/custom/path/icons.yml"
    config.fonts_dir = "/custom/fonts"
    config.build_dir = "/custom/builds"

    assert_equal "/custom/path/icons.yml", config.meta_path
    assert_equal "/custom/fonts", config.fonts_dir
    assert_equal "/custom/builds", config.build_dir
  end

  def test_scss_template_default_is_nil
    config = FontawesomeSubsetter.configuration
    assert_nil config.scss_template
  end

  def test_styles_default_is_nil
    config = FontawesomeSubsetter.configuration
    assert_nil config.styles
  end

end
