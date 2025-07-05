require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  test "is not valid without title" do
    assignment = Assignment.new(
      user: users(:teacher),
      instructions: "Instructions",
      title: nil,
      grade_level: "9",
      feedback_tone: "encouraging"
    )
    assert_not assignment.valid?
  end

  test "is not valid without instructions" do
    assignment = Assignment.new(
      user: users(:teacher),
      title: "Title",
      instructions: nil,
      grade_level: "9",
      feedback_tone: "encouraging"
    )
    assert_not assignment.valid?
  end

  test "is not valid without grade level" do
    assignment = Assignment.new(
      user: users(:teacher),
      title: "Title",
      instructions: "Instructions",
      grade_level: nil,
      feedback_tone: "encouraging"
    )
    assert_not assignment.valid?
  end

  test "is not valid without feedback tone" do
    assignment = Assignment.new(
      user: users(:teacher),
      title: "Title",
      instructions: "Instructions",
      grade_level: "9",
      feedback_tone: nil
    )
    assert_not assignment.valid?
  end

  test "feedback tone must be valid" do
    valid_tones = Assignment::FEEDBACK_TONES
    valid_tones.each do |tone|
      assignment = Assignment.new(
        user: users(:teacher),
        title: "Title",
        instructions: "Instructions",
        grade_level: "9",
        feedback_tone: tone
      )
      assert assignment.valid?, assignment.errors.full_messages
    end

    invalid_assignment = Assignment.new(
      user: users(:teacher),
      title: "Title",
      instructions: "Instructions",
      grade_level: "9",
      feedback_tone: "invalid_tone"
    )
    assert_not invalid_assignment.valid?, invalid_assignment.errors.full_messages
  end

  test "processing_complete? returns true when all processing steps are completed" do
    assignment1 = assignments(:english_essay)
    assignment1.processing_steps.update_all(status: "completed")

    assignment2 = assignments(:history_essay)
    assignment2.processing_steps.create(step_key: "rubric", status: "in_progress")

    assert assignment1.processing_complete?
    assert_not assignment2.processing_complete?
  end
end
