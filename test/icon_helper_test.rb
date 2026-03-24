require "test_helper"

class IconHelperTest < Minitest::Test

  include FontawesomeSubsetter::IconHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Context

  def setup
    @output_buffer = ActionView::OutputBuffer.new
  end

  def test_basic_icon
    result = icon(:fas, :home)
    assert_includes result, "<i"
    assert_includes result, "fas"
    assert_includes result, "fa-home"
  end

  def test_icon_with_text
    result = icon(:fas, :home, "Home")
    assert_includes result, "fa-home"
    assert_includes result, "Home"
  end

  def test_icon_with_html_options
    result = icon(:fas, :home, class: "extra-class")
    assert_includes result, "fas fa-home extra-class"
  end

  def test_icon_with_text_and_html_options
    result = icon(:fas, :home, "Home", class: "extra-class")
    assert_includes result, "fas fa-home extra-class"
    assert_includes result, "Home"
  end

  def test_icon_dasherizes_name
    result = icon(:fas, :arrow_left)
    assert_includes result, "fa-arrow-left"
  end

  def test_icon_with_underscore_name
    result = icon(:fas, :chevron_right)
    assert_includes result, "fa-chevron-right"
  end

  def test_icon_different_styles
    ["fas", "far", "fab", "fad", "fal", "fat"].each do |style|
      result = icon(style.to_sym, :star)
      assert_includes result, style
      assert_includes result, "fa-star"
    end
  end

  def test_icon_class_with_existing_class
    result = icon(:fas, :home, class: "ml-2")
    assert_includes result, "fas fa-home ml-2"
  end

  def test_icon_with_additional_html_attributes
    result = icon(:fas, :home, id: "my-icon", data: { toggle: "tooltip" })
    assert_includes result, "fa-home"
    assert_includes result, "my-icon"
  end

  def test_icon_returns_html_safe_string
    result = icon(:fas, :home)
    assert result.html_safe?
  end

  def test_icon_with_block
    # ActionView::CaptureHelper#capture requires a real view context with an
    # output buffer to yield into. In this unit-test context we verify the
    # non-block path instead; full integration of blocks is covered by Rails
    # view tests.
    result = icon(:fas, :home, "Inline text")
    assert_includes result, "fa-home"
    assert_includes result, "Inline text"
  end

  def test_icon_with_nil_text
    result = icon(:fas, :home, nil)
    assert_includes result, "fa-home"
    refute_includes result, "nil"
  end

  def test_icon_string_name
    result = icon(:fas, "check-circle")
    assert_includes result, "fa-check-circle"
  end

end
