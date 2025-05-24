require "test_helper"

class PromptTemplateTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
    @template = PromptTemplate.new
  end

  test "builds prompt for rubric generation" do
    rubric_prompt_input = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", rubric_prompt_input)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
    assert prompt.include?(@assignment.grade_level)
  end

  test "builds prompt for student work grading" do
    student_work_prompt_input = DataCollectionService.collect(@student_work, "grade_student_work", @user)
    prompt = @template.build("grade_student_work", student_work_prompt_input)

    assert_not_nil prompt
    assert prompt.include?(@student_work.assignment.title)
    assert prompt.include?(@student_work.assignment.instructions)
    assert prompt.include?(@student_work.selected_document.title)
  end

  test "builds prompt for assignment summary feedback" do
    summary_feedback_prompt_input = DataCollectionService.collect(@assignment, "generate_summary_feedback", @user)
    prompt = @template.build("generate_summary_feedback", summary_feedback_prompt_input)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
  end

  test "raises error for unsupported process type" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    error = assert_raises(PromptTemplate::UnsupportedProcessTypeError) do
      @template.build("unknown_type", data)
    end

    assert_match(/Unsupported process type/, error.message)
  end

  test "handles ERB rendering errors gracefully" do
    # Mock the file read to return invalid ERB content
    invalid_erb_content = "Assignment: <%= rubric_prompt_input.nonexistent_field.some_method %>"

    File.expects(:read).returns(invalid_erb_content)

    rubric_prompt_input = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    error = assert_raises(NoMethodError) do
      @template.build("generate_rubric", rubric_prompt_input)
    end

    assert_match(/undefined method.*nonexistent_field.*for.*RubricPromptInput/, error.message)
  end

  test "interpolates variables correctly in templates" do
    # Mock the file read to return our test template with new rubric_prompt_input format
    test_template_content = "Assignment: <%= rubric_prompt_input.assignment_title %>\nInstructions: <%= rubric_prompt_input.instructions %>"
    File.expects(:read).returns(test_template_content)

    rubric_prompt_input = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", rubric_prompt_input)

    assert prompt.include?("Assignment: #{@assignment.title}")
    assert prompt.include?("Instructions: #{@assignment.instructions}")
  end

  test "uses RubricPromptInput PORO for rubric generation templates" do
    # Mock template with new rubric_prompt_input format
    new_template_content = "Title: <%= rubric_prompt_input.assignment_title %>\nSubject: <%= rubric_prompt_input.subject %>\nGrade: <%= rubric_prompt_input.grade_level %>"
    File.expects(:read).returns(new_template_content)

    rubric_prompt_input = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", rubric_prompt_input)

    assert prompt.include?("Title: #{@assignment.title}")
    assert prompt.include?("Subject: #{@assignment.subject}")
    assert prompt.include?("Grade: #{@assignment.grade_level}")
  end

  test "handles rubric_text_present conditional in templates" do
    # Test with assignment that has rubric text
    assignment_with_rubric = assignments(:english_essay_with_rubric_text)
    new_template_content = "<% if rubric_prompt_input.rubric_text_present? -%>Rubric: <%= rubric_prompt_input.rubric_text %><% end -%>"
    File.expects(:read).returns(new_template_content)

    rubric_prompt_input = DataCollectionService.collect(assignment_with_rubric, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", rubric_prompt_input)

    assert prompt.include?("Rubric:")
    assert prompt.include?(assignment_with_rubric.rubric_text)
  end

  test "validates template data before rendering for rubric generation" do
    # Test that the template validates required RubricPromptInput
    invalid_data = "not a rubric prompt input"

    error = assert_raises(PromptTemplate::InvalidDataError) do
      @template.build("generate_rubric", invalid_data)
    end

    assert_match(/Invalid or incomplete data/, error.message)
    assert_match(/missing rubric_prompt_input/, error.message)
  end

  test "validates template data before rendering for student work grading" do
    # Test that the template validates required StudentWorkPromptInput
    invalid_data = "not a student work prompt input"

    error = assert_raises(PromptTemplate::InvalidDataError) do
      @template.build("grade_student_work", invalid_data)
    end

    assert_match(/Invalid or incomplete data/, error.message)
    assert_match(/missing student_work_prompt_input/, error.message)
  end

  test "validates template data before rendering for summary feedback" do
    # Test that the template validates required SummaryFeedbackPromptInput
    invalid_data = "not a summary feedback prompt input"

    error = assert_raises(PromptTemplate::InvalidDataError) do
      @template.build("generate_summary_feedback", invalid_data)
    end

    assert_match(/Invalid or incomplete data/, error.message)
    assert_match(/missing summary_feedback_prompt_input/, error.message)
  end
end
