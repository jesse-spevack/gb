require "test_helper"

class RubricHelperTest < ActionView::TestCase
  include RubricHelper

  test "performance_level_color_classes returns correct colors for each performance level" do
    assert_equal "bg-green-100 text-green-800", performance_level_color_classes("exceeds")
    assert_equal "bg-green-100 text-green-800", performance_level_color_classes(:exceeds)

    assert_equal "bg-blue-100 text-blue-800", performance_level_color_classes("meets")
    assert_equal "bg-blue-100 text-blue-800", performance_level_color_classes(:meets)

    assert_equal "bg-amber-100 text-amber-800", performance_level_color_classes("approaching")
    assert_equal "bg-amber-100 text-amber-800", performance_level_color_classes(:approaching)

    assert_equal "bg-red-100 text-red-800", performance_level_color_classes("below")
    assert_equal "bg-red-100 text-red-800", performance_level_color_classes(:below)
  end

  test "performance_level_color_classes returns default for unknown levels" do
    assert_equal "bg-gray-100 text-gray-800", performance_level_color_classes("unknown")
    assert_equal "bg-gray-100 text-gray-800", performance_level_color_classes(nil)
    assert_equal "bg-gray-100 text-gray-800", performance_level_color_classes("")
  end

  test "performance_level_icon returns correct icons for each performance level" do
    assert_equal "star", performance_level_icon("exceeds")
    assert_equal "star", performance_level_icon(:exceeds)

    assert_equal "checkmark", performance_level_icon("meets")
    assert_equal "checkmark", performance_level_icon(:meets)

    assert_equal "exclamation", performance_level_icon("approaching")
    assert_equal "exclamation", performance_level_icon(:approaching)

    assert_equal "x_circle", performance_level_icon("below")
    assert_equal "x_circle", performance_level_icon(:below)
  end

  test "performance_level_icon returns default for unknown levels" do
    assert_equal "star", performance_level_icon("unknown")
    assert_equal "star", performance_level_icon(nil)
    assert_equal "star", performance_level_icon("")
  end

  test "performance_level_text returns standardized text for each performance level" do
    assert_equal "Exceeds", performance_level_text("exceeds")
    assert_equal "Exceeds", performance_level_text(:exceeds)

    assert_equal "Meets", performance_level_text("meets")
    assert_equal "Meets", performance_level_text(:meets)

    assert_equal "Approaching", performance_level_text("approaching")
    assert_equal "Approaching", performance_level_text(:approaching)

    assert_equal "Below", performance_level_text("below")
    assert_equal "Below", performance_level_text(:below)
  end

  test "performance_level_text returns not assessed for unrecognized levels" do
    assert_equal "Not assessed", performance_level_text("unknown")
    assert_equal "Not assessed", performance_level_text(nil)
    assert_equal "Not assessed", performance_level_text("")
  end

  test "performance_badge_size_classes returns correct sizes" do
    sm_classes = performance_badge_size_classes("sm")
    assert_equal "px-3 py-1 text-sm", sm_classes[:wrapper]
    assert_equal "w-4 h-4", sm_classes[:icon]

    md_classes = performance_badge_size_classes("md")
    assert_equal "px-4 py-2", md_classes[:wrapper]
    assert_equal "w-5 h-5", md_classes[:icon]

    lg_classes = performance_badge_size_classes("lg")
    assert_equal "px-6 py-3 text-lg", lg_classes[:wrapper]
    assert_equal "w-6 h-6", lg_classes[:icon]
  end

  test "performance_badge_size_classes returns default size for unknown sizes" do
    unknown_classes = performance_badge_size_classes("unknown")
    assert_equal "px-4 py-2", unknown_classes[:wrapper]
    assert_equal "w-5 h-5", unknown_classes[:icon]

    nil_classes = performance_badge_size_classes(nil)
    assert_equal "px-4 py-2", nil_classes[:wrapper]
    assert_equal "w-5 h-5", nil_classes[:icon]
  end

  test "normalize_performance_level handles mixed case and whitespace" do
    # Test the private method indirectly through public methods
    assert_equal "bg-green-100 text-green-800", performance_level_color_classes("EXCEEDS")
    assert_equal "bg-green-100 text-green-800", performance_level_color_classes(" exceeds ")
    assert_equal "bg-blue-100 text-blue-800", performance_level_color_classes("Meets")
  end

  test "all helper methods work together for complete badge styling" do
    level = "exceeds"
    size = "md"

    color_classes = performance_level_color_classes(level)
    size_classes = performance_badge_size_classes(size)
    icon_name = performance_level_icon(level)
    display_text = performance_level_text(level)

    assert_equal "bg-green-100 text-green-800", color_classes
    assert_equal "px-4 py-2", size_classes[:wrapper]
    assert_equal "w-5 h-5", size_classes[:icon]
    assert_equal "star", icon_name
    assert_equal "Exceeds", display_text
  end

  test "helper methods handle Level model objects" do
    # Create a level with performance_level enum
    criterion = Criterion.create!(
      rubric: rubrics(:english_essay_rubric),
      title: "Test Criterion",
      description: "Test description",
      position: 1
    )

    level = Level.create!(
      criterion: criterion,
      title: "Exceeds",
      description: "Excellent performance",
      performance_level: :exceeds,
      points: 4
    )

    # Test that helper methods work with Level objects
    assert_equal "bg-green-100 text-green-800", performance_level_color_classes(level.performance_level)
    assert_equal "star", performance_level_icon(level.performance_level)
    assert_equal "Exceeds", performance_level_text(level.performance_level)
  end

  test "performance_level_border_classes returns correct border styles" do
    assert_equal "border-green-500 bg-green-100", performance_level_border_classes("exceeds")
    assert_equal "border-blue-500 bg-blue-100", performance_level_border_classes("meets")
    assert_equal "border-amber-500 bg-amber-100", performance_level_border_classes("approaching")
    assert_equal "border-red-500 bg-red-100", performance_level_border_classes("below")
    assert_equal "border-gray-500 bg-gray-100", performance_level_border_classes("unknown")
  end

  test "performance_level_text_classes returns correct text colors" do
    assert_equal "text-green-600", performance_level_text_classes("exceeds")
    assert_equal "text-blue-600", performance_level_text_classes("meets")
    assert_equal "text-amber-600", performance_level_text_classes("approaching")
    assert_equal "text-red-600", performance_level_text_classes("below")
    assert_equal "text-gray-600", performance_level_text_classes("unknown")
  end

  test "performance_level_classes returns appropriate classes for different contexts" do
    # Badge context (default)
    badge_classes = performance_level_classes("exceeds", :badge)
    assert_includes badge_classes, "inline-flex items-center rounded-full font-semibold"
    assert_includes badge_classes, "bg-green-100 text-green-800"

    # Border context
    border_classes = performance_level_classes("meets", :border)
    assert_equal "border-blue-500 bg-blue-100", border_classes

    # Text context
    text_classes = performance_level_classes("approaching", :text)
    assert_equal "text-amber-600", text_classes

    # Default context (badge)
    default_classes = performance_level_classes("below")
    assert_includes default_classes, "inline-flex items-center rounded-full font-semibold"
    assert_includes default_classes, "bg-red-100 text-red-800"
  end

  test "points_for_performance_level returns correct point values" do
    assert_equal 4, points_for_performance_level(:exceeds)
    assert_equal 3, points_for_performance_level(:meets)
    assert_equal 2, points_for_performance_level(:approaching)
    assert_equal 1, points_for_performance_level(:below)
    assert_equal 3, points_for_performance_level(:unknown) # defaults to meets
  end

  test "normalize_performance_level handles legacy level names" do
    # Test through public methods since normalize_performance_level is private
    assert_equal "Exceeds", performance_level_text("excellent")
    assert_equal "Meets", performance_level_text("good")
    assert_equal "Meets", performance_level_text("proficient")
    assert_equal "Approaching", performance_level_text("needs improvement")
    assert_equal "Below", performance_level_text("poor")
  end

  # Check result badge tests
  test "check_result_confidence_level returns correct levels for score ranges" do
    assert_equal :low, check_result_confidence_level(0)
    assert_equal :low, check_result_confidence_level(15)
    assert_equal :low, check_result_confidence_level(33)

    assert_equal :unclear, check_result_confidence_level(34)
    assert_equal :unclear, check_result_confidence_level(50)
    assert_equal :unclear, check_result_confidence_level(66)

    assert_equal :high, check_result_confidence_level(67)
    assert_equal :high, check_result_confidence_level(85)
    assert_equal :high, check_result_confidence_level(100)

    assert_equal :no_data, check_result_confidence_level(nil)
  end

  test "check_result_confidence_level handles edge cases" do
    assert_equal :unclear, check_result_confidence_level(150)
    assert_equal :unclear, check_result_confidence_level(-10)
  end

  test "check_result_badge_color_classes returns correct colors" do
    assert_equal "bg-green-100 text-green-800", check_result_badge_color_classes(:low)
    assert_equal "bg-gray-100 text-gray-800", check_result_badge_color_classes(:unclear)
    assert_equal "bg-gray-100 text-gray-800", check_result_badge_color_classes(:no_data)
    assert_equal "bg-red-100 text-red-800", check_result_badge_color_classes(:high)
    assert_equal "bg-gray-100 text-gray-800", check_result_badge_color_classes(:unknown)
  end

  test "check_result_badge_text returns correct text" do
    assert_equal "Low", check_result_badge_text(:low)
    assert_equal "Unclear", check_result_badge_text(:unclear)
    assert_equal "High", check_result_badge_text(:high)
    assert_equal "No data", check_result_badge_text(:no_data)
    assert_equal "Unclear", check_result_badge_text(:unknown)
  end

  test "check result badge methods work together" do
    score = 25
    level = check_result_confidence_level(score)
    color_classes = check_result_badge_color_classes(level)
    text = check_result_badge_text(level)

    assert_equal :low, level
    assert_equal "bg-green-100 text-green-800", color_classes
    assert_equal "Low", text
  end
end
