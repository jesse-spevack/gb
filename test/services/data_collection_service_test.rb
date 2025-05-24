require "test_helper"

class DataCollectionServiceTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
  end

  test "returns only template-needed data for rubric generation" do
    result = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # Should return RubricPromptInput directly, not wrapped in metadata hash
    assert result.is_a?(RubricPromptInput)
    assert_equal @assignment.title, result.assignment_title
    assert_equal @assignment.subject, result.subject
  end

    test "returns RubricPromptInput directly for rubric generation" do
    result = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # Should return RubricPromptInput directly
    assert result.is_a?(RubricPromptInput)
    assert_equal @assignment.title, result.assignment_title
    assert_equal @assignment.subject, result.subject
    assert_equal @assignment.grade_level, result.grade_level
    assert_equal @assignment.instructions, result.instructions
    assert_nil result.rubric_text  # english_essay fixture has no rubric_text
    assert_equal @assignment.feedback_tone, result.feedback_tone
  end

  test "collects student work data for grading" do
    student_work_prompt_input = DataCollectionService.collect(@student_work, "grade_student_work", @user)

    # Should return StudentWorkPromptInput directly
    assert student_work_prompt_input.is_a?(StudentWorkPromptInput)

    # Student work context
    assert_equal @student_work.id, student_work_prompt_input.student_work_id
    assert_equal @student_work.assignment_id, student_work_prompt_input.assignment_id
    assert_equal @student_work.selected_document_id, student_work_prompt_input.selected_document_id

    # Assignment context for grading
    assert_equal @student_work.assignment.title, student_work_prompt_input.assignment_title
    assert_equal @student_work.assignment.instructions, student_work_prompt_input.assignment_instructions
    assert_equal @student_work.assignment.feedback_tone, student_work_prompt_input.assignment_feedback_tone

    # Selected document info
    assert_equal @student_work.selected_document.title, student_work_prompt_input.selected_document_title
    assert_equal @student_work.selected_document.google_doc_id, student_work_prompt_input.selected_document_google_doc_id

    # Rubric data if available
    if @student_work.assignment.rubric.present?
      assert student_work_prompt_input.rubric_present?
    else
      assert_not student_work_prompt_input.rubric_present?
    end
  end

  test "collects assignment summary data for summary feedback" do
    summary_feedback_prompt_input = DataCollectionService.collect(@assignment, "generate_summary_feedback", @user)

    # Should return SummaryFeedbackPromptInput directly
    assert summary_feedback_prompt_input.is_a?(SummaryFeedbackPromptInput)

    # Assignment context
    assert_equal @assignment.title, summary_feedback_prompt_input.assignment_title
    assert_equal @assignment.instructions, summary_feedback_prompt_input.assignment_instructions

    # Student works collection
    assert summary_feedback_prompt_input.student_works.is_a?(Array)
    assert_equal @assignment.student_works.count, summary_feedback_prompt_input.student_works_count

    if @assignment.student_works.any?
      first_work = summary_feedback_prompt_input.student_works.first
      assert_not_nil first_work[:id]
      assert_not_nil first_work[:qualitative_feedback] if first_work[:qualitative_feedback]
    end

    # Rubric context
    if @assignment.rubric.present?
      assert summary_feedback_prompt_input.rubric_present?
    else
      assert_not summary_feedback_prompt_input.rubric_present?
    end
  end

  test "handles assignment without rubric text" do
    # Create an assignment that definitely has no rubric
    assignment_without_rubric = Assignment.create!(
      user: @user,
      title: "Test Assignment Without Rubric",
      subject: "Test",
      grade_level: "10",
      instructions: "This is a test assignment",
      feedback_tone: "encouraging"
    )

    result = DataCollectionService.collect(assignment_without_rubric, "generate_rubric", @user)

    assert result.is_a?(RubricPromptInput)
    assert_nil result.rubric_text
    assert_not result.rubric_text_present?
  end

  test "raises error for unsupported processable type" do
    unsupported_object = Object.new

    error = assert_raises(DataCollectionService::UnsupportedProcessableError) do
      DataCollectionService.collect(unsupported_object, "generate_rubric", @user)
    end

    assert_match(/Unsupported processable type/, error.message)
  end

  test "raises error for unsupported process type" do
    error = assert_raises(DataCollectionService::UnsupportedProcessTypeError) do
      DataCollectionService.collect(@assignment, "unknown_process", @user)
    end

    assert_match(/Unsupported process type/, error.message)
  end

  test "handles nil user gracefully for rubric generation" do
    result = DataCollectionService.collect(@assignment, "generate_rubric", nil)

    # Should still return RubricPromptInput even with nil user
    assert result.is_a?(RubricPromptInput)
    assert_equal @assignment.title, result.assignment_title
  end

  test "includes relevant associations in collected data" do
    # Test that associations are properly loaded via the POROes
    student_work_prompt_input = DataCollectionService.collect(@student_work, "grade_student_work", @user)

    # Should include related models through the PORO structure
    assert_not_nil student_work_prompt_input.assignment_title
    assert_not_nil student_work_prompt_input.selected_document_title

    # Verify we're getting complete data from associations
    assert_equal @student_work.assignment.title, student_work_prompt_input.assignment_title
    assert_equal @student_work.selected_document.title, student_work_prompt_input.selected_document_title
  end
end
