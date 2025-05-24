require "test_helper"

class SummaryFeedbackPromptInputTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
  end

  test "creates from assignment with all attributes" do
    summary_feedback_prompt_input = SummaryFeedbackPromptInput.from(assignment: @assignment, user: @user)

    # Assignment attributes
    assert_equal @assignment.id, summary_feedback_prompt_input.assignment_id
    assert_equal @assignment.title, summary_feedback_prompt_input.assignment_title
    assert_equal @assignment.subject, summary_feedback_prompt_input.assignment_subject
    assert_equal @assignment.grade_level, summary_feedback_prompt_input.assignment_grade_level
    assert_equal @assignment.instructions, summary_feedback_prompt_input.assignment_instructions
    assert_equal @assignment.feedback_tone, summary_feedback_prompt_input.assignment_feedback_tone

    # User attributes
    assert_equal @user.id, summary_feedback_prompt_input.user_id
    assert_equal @user.name, summary_feedback_prompt_input.user_name
    assert_equal @user.email, summary_feedback_prompt_input.user_email

    # Student works
    assert summary_feedback_prompt_input.student_works.is_a?(Array)
    assert_equal @assignment.student_works.count, summary_feedback_prompt_input.student_works_count
  end

  test "handles nil user" do
    summary_feedback_prompt_input = SummaryFeedbackPromptInput.from(assignment: @assignment, user: nil)

    assert_nil summary_feedback_prompt_input.user_id
    assert_nil summary_feedback_prompt_input.user_name
    assert_nil summary_feedback_prompt_input.user_email
  end

  test "includes rubric data when assignment has rubric" do
    assignment_with_rubric = assignments(:english_essay_with_rubric_text)
    summary_feedback_prompt_input = SummaryFeedbackPromptInput.from(assignment: assignment_with_rubric, user: @user)

    assert summary_feedback_prompt_input.rubric_present?
    assert_not_nil summary_feedback_prompt_input.rubric
    assert summary_feedback_prompt_input.rubric[:criteria].is_a?(Array)
  end

  test "handles assignment without rubric" do
    # Create an assignment without any rubric
    assignment_without_rubric = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment Without Rubric",
      subject: "Test",
      grade_level: "10",
      instructions: "This is a test assignment",
      feedback_tone: "encouraging"
    )

    summary_feedback_prompt_input = SummaryFeedbackPromptInput.from(assignment: assignment_without_rubric, user: @user)

    assert_not summary_feedback_prompt_input.rubric_present?
    assert_nil summary_feedback_prompt_input.rubric
  end

  test "includes student works data" do
    summary_feedback_prompt_input = SummaryFeedbackPromptInput.from(assignment: @assignment, user: @user)

    # Should include student works data if any exist
    if @assignment.student_works.any?
      first_work_data = summary_feedback_prompt_input.student_works.first
      first_work = @assignment.student_works.first

      assert_equal first_work.id, first_work_data[:id]
      assert_equal first_work.assignment_id, first_work_data[:assignment_id]
      assert_equal first_work.selected_document_id, first_work_data[:selected_document_id]
      assert_equal first_work.qualitative_feedback, first_work_data[:qualitative_feedback]
    end
  end

  test "can be created manually with all required fields" do
    student_works_data = [
      {
        id: 1,
        assignment_id: 456,
        selected_document_id: 789,
        qualitative_feedback: "Great work!",
        created_at: Time.current
      },
      {
        id: 2,
        assignment_id: 456,
        selected_document_id: 790,
        qualitative_feedback: "Needs improvement",
        created_at: Time.current
      }
    ]

    summary_feedback_prompt_input = SummaryFeedbackPromptInput.new(
      assignment_id: 456,
      assignment_title: "Test Assignment",
      assignment_subject: "Math",
      assignment_grade_level: "8",
      assignment_instructions: "Solve the problems",
      assignment_feedback_tone: "encouraging",
      student_works: student_works_data,
      user_id: 1,
      user_name: "Teacher Name",
      user_email: "teacher@example.com",
      rubric: { criteria: [] }
    )

    assert_equal 456, summary_feedback_prompt_input.assignment_id
    assert_equal "Test Assignment", summary_feedback_prompt_input.assignment_title
    assert_equal "Math", summary_feedback_prompt_input.assignment_subject
    assert_equal 2, summary_feedback_prompt_input.student_works_count
    assert_equal 1, summary_feedback_prompt_input.user_id
    assert summary_feedback_prompt_input.rubric_present?
  end

  test "can be created manually with optional fields as nil" do
    summary_feedback_prompt_input = SummaryFeedbackPromptInput.new(
      assignment_id: 456,
      assignment_title: "Test Assignment",
      assignment_subject: "Math",
      assignment_grade_level: "8",
      assignment_instructions: "Solve the problems",
      assignment_feedback_tone: "encouraging",
      student_works: []
    )

    assert_nil summary_feedback_prompt_input.user_id
    assert_nil summary_feedback_prompt_input.user_name
    assert_nil summary_feedback_prompt_input.user_email
    assert_nil summary_feedback_prompt_input.rubric
    assert_not summary_feedback_prompt_input.rubric_present?
    assert_equal 0, summary_feedback_prompt_input.student_works_count
  end
end
