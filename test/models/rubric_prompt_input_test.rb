require "test_helper"

class RubricPromptInputTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
  end

  test "creates from assignment with all attributes" do
    rubric_prompt_input = RubricPromptInput.from(assignment: @assignment)

    assert_equal @assignment.title, rubric_prompt_input.assignment_title
    assert_equal @assignment.subject, rubric_prompt_input.subject
    assert_equal @assignment.grade_level, rubric_prompt_input.grade_level
    assert_equal @assignment.instructions, rubric_prompt_input.instructions
    assert_nil rubric_prompt_input.rubric_text  # english_essay fixture has no rubric_text
    assert_equal @assignment.feedback_tone, rubric_prompt_input.feedback_tone
  end

  test "handles nil rubric_text" do
    # english_essay fixture has no rubric_text (nil)
    rubric_prompt_input = RubricPromptInput.from(assignment: @assignment)

    assert_nil rubric_prompt_input.rubric_text
    assert_not rubric_prompt_input.rubric_text_present?
  end

  test "handles blank rubric_text" do
    assignment_with_blank_rubric = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment",
      subject: "Test",
      grade_level: "10",
      instructions: "Test instructions",
      rubric_text: "",
      feedback_tone: "encouraging"
    )

    rubric_prompt_input = RubricPromptInput.from(assignment: assignment_with_blank_rubric)

    assert_equal "", rubric_prompt_input.rubric_text
    assert_not rubric_prompt_input.rubric_text_present?
  end

  test "detects present rubric_text" do
    assignment_with_rubric = assignments(:english_essay_with_rubric_text)
    rubric_prompt_input = RubricPromptInput.from(assignment: assignment_with_rubric)

    assert rubric_prompt_input.rubric_text_present?
    assert_not_nil rubric_prompt_input.rubric_text
  end

  test "can be created manually with required fields" do
    rubric_prompt_input = RubricPromptInput.new(
      assignment_title: "Test Assignment",
      subject: "Math",
      grade_level: "8",
      instructions: "Solve the problems",
      feedback_tone: "encouraging"
    )

    assert_equal "Test Assignment", rubric_prompt_input.assignment_title
    assert_equal "Math", rubric_prompt_input.subject
    assert_equal "8", rubric_prompt_input.grade_level
    assert_equal "Solve the problems", rubric_prompt_input.instructions
    assert_nil rubric_prompt_input.rubric_text
    assert_equal "encouraging", rubric_prompt_input.feedback_tone
    assert_not rubric_prompt_input.rubric_text_present?
  end

  test "can be created manually with optional rubric_text" do
    rubric_prompt_input = RubricPromptInput.new(
      assignment_title: "Test Assignment",
      subject: "Math",
      grade_level: "8",
      instructions: "Solve the problems",
      rubric_text: "Use clear mathematical reasoning",
      feedback_tone: "encouraging"
    )

    assert_equal "Use clear mathematical reasoning", rubric_prompt_input.rubric_text
    assert rubric_prompt_input.rubric_text_present?
  end
end
