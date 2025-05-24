require "test_helper"

class StudentWorkPromptInputTest < ActiveSupport::TestCase
  def setup
    @student_work = student_works(:student_essay_one)
    @assignment = @student_work.assignment
    @selected_document = @student_work.selected_document
    @user = users(:teacher)
  end

  test "creates from student work with all attributes" do
    student_work_prompt_input = StudentWorkPromptInput.from(student_work: @student_work, user: @user)

    assert_equal @student_work.id, student_work_prompt_input.student_work_id
    assert_equal @student_work.assignment_id, student_work_prompt_input.assignment_id
    assert_equal @student_work.selected_document_id, student_work_prompt_input.selected_document_id
    assert_equal @student_work.qualitative_feedback, student_work_prompt_input.qualitative_feedback

    # Assignment attributes
    assert_equal @assignment.title, student_work_prompt_input.assignment_title
    assert_equal @assignment.subject, student_work_prompt_input.assignment_subject
    assert_equal @assignment.grade_level, student_work_prompt_input.assignment_grade_level
    assert_equal @assignment.instructions, student_work_prompt_input.assignment_instructions
    assert_equal @assignment.feedback_tone, student_work_prompt_input.assignment_feedback_tone

    # Selected document attributes
    assert_equal @selected_document.title, student_work_prompt_input.selected_document_title
    assert_equal @selected_document.google_doc_id, student_work_prompt_input.selected_document_google_doc_id
    assert_equal @selected_document.url, student_work_prompt_input.selected_document_url
    assert_not_nil student_work_prompt_input.document_content

    # User attributes
    assert_equal @user.id, student_work_prompt_input.user_id
    assert_equal @user.name, student_work_prompt_input.user_name
    assert_equal @user.email, student_work_prompt_input.user_email
  end

  test "handles nil user" do
    student_work_prompt_input = StudentWorkPromptInput.from(student_work: @student_work, user: nil)

    assert_nil student_work_prompt_input.user_id
    assert_nil student_work_prompt_input.user_name
    assert_nil student_work_prompt_input.user_email
  end

  test "includes rubric data when assignment has rubric" do
    assignment_with_rubric = assignments(:english_essay_with_rubric_text)
    student_work = StudentWork.create!(
      assignment: assignment_with_rubric,
      selected_document: @selected_document,
      qualitative_feedback: "Sample feedback"
    )

    student_work_prompt_input = StudentWorkPromptInput.from(student_work: student_work, user: @user)

    assert student_work_prompt_input.rubric_present?
    assert_not_nil student_work_prompt_input.rubric
    assert student_work_prompt_input.rubric[:criteria].is_a?(Array)
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

    student_work_without_rubric = StudentWork.create!(
      assignment: assignment_without_rubric,
      selected_document: @selected_document,
      qualitative_feedback: "Sample feedback"
    )

    student_work_prompt_input = StudentWorkPromptInput.from(student_work: student_work_without_rubric, user: @user)

    assert_not student_work_prompt_input.rubric_present?
    assert_nil student_work_prompt_input.rubric
  end

  test "can be created manually with all required fields" do
    student_work_prompt_input = StudentWorkPromptInput.new(
      student_work_id: 123,
      assignment_id: 456,
      selected_document_id: 789,
      qualitative_feedback: "Great work!",
      assignment_title: "Test Assignment",
      assignment_subject: "Math",
      assignment_grade_level: "8",
      assignment_instructions: "Solve the problems",
      assignment_feedback_tone: "encouraging",
      selected_document_title: "Student Document",
      selected_document_google_doc_id: "doc123",
      selected_document_url: "https://docs.google.com/document/d/doc123",
      document_content: "This is the student's work content...",
      user_id: 1,
      user_name: "Teacher Name",
      user_email: "teacher@example.com",
      rubric: { criteria: [] }
    )

    assert_equal 123, student_work_prompt_input.student_work_id
    assert_equal "Test Assignment", student_work_prompt_input.assignment_title
    assert_equal "Math", student_work_prompt_input.assignment_subject
    assert_equal "Student Document", student_work_prompt_input.selected_document_title
    assert_equal "This is the student's work content...", student_work_prompt_input.document_content
    assert_equal 1, student_work_prompt_input.user_id
    assert student_work_prompt_input.rubric_present?
  end

  test "can be created manually with optional fields as nil" do
    student_work_prompt_input = StudentWorkPromptInput.new(
      student_work_id: 123,
      assignment_id: 456,
      selected_document_id: 789,
      qualitative_feedback: nil,
      assignment_title: "Test Assignment",
      assignment_subject: "Math",
      assignment_grade_level: "8",
      assignment_instructions: "Solve the problems",
      assignment_feedback_tone: "encouraging",
      selected_document_title: "Student Document",
      selected_document_google_doc_id: "doc123",
      selected_document_url: "https://docs.google.com/document/d/doc123",
      document_content: "Student work content here..."
    )

    assert_nil student_work_prompt_input.qualitative_feedback
    assert_nil student_work_prompt_input.user_id
    assert_nil student_work_prompt_input.user_name
    assert_nil student_work_prompt_input.user_email
    assert_nil student_work_prompt_input.rubric
    assert_not student_work_prompt_input.rubric_present?
  end
end
