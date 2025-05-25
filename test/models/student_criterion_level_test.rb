require "test_helper"

class StudentCriterionLevelTest < ActiveSupport::TestCase
  test "is not valid without an explanation" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: nil,
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient)
    )
    assert_not student_criterion_level.valid?
  end

  test "is not valid without a criterion" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      criterion: nil,
      level: levels(:writing_proficient)
    )
    assert_not student_criterion_level.valid?
  end

  test "is not valid without a level" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      level: nil,
      criterion: criteria(:writing_quality)
    )
    assert_not student_criterion_level.valid?
  end

  test "is not valid if the level does not belong to the criterion" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      level: levels(:writing_proficient),
      criterion: criteria(:grammar_mechanics)
    )
    assert_not student_criterion_level.valid?
  end

  test "is valid with a valid explanation, criterion, and level" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient)
    )
    assert student_criterion_level.valid?, student_criterion_level.errors.full_messages
  end

  test "criterion_title returns the title of the associated criterion" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient)
    )

    assert_equal criteria(:writing_quality).title, student_criterion_level.criterion_title
  end

  test "level_title returns the title of the associated level" do
    student_criterion_level = StudentCriterionLevel.new(
      student_work: student_works(:student_essay_one),
      explanation: "This is a valid explanation",
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient)
    )

    assert_equal levels(:writing_proficient).title, student_criterion_level.level_title
  end
end
