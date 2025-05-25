require "test_helper"

class CriterionLevelDataTest < ActiveSupport::TestCase
  def setup
    @criterion = criteria(:writing_quality)
    @level = levels(:writing_exemplary)
    @student_criterion_level = StudentCriterionLevel.new(
      criterion: @criterion,
      level: @level,
      explanation: "This shows excellent writing skills"
    )
  end

  test "provides criterion title" do
    data = CriterionLevelData.new(@student_criterion_level)
    assert_equal @criterion.title, data.criterion_title
  end

  test "provides level title" do
    data = CriterionLevelData.new(@student_criterion_level)
    assert_equal @level.title, data.level_title
  end

  test "provides explanation" do
    data = CriterionLevelData.new(@student_criterion_level)
    assert_equal @student_criterion_level.explanation, data.explanation
  end
end
