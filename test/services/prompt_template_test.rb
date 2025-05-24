require "test_helper"

class PromptTemplateTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
    @template = PromptTemplate.new
  end

  test "builds prompt for rubric generation" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", data)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
    assert prompt.include?(@assignment.grade_level)
  end

  test "builds prompt for student work grading" do
    data = DataCollectionService.collect(@student_work, "grade_student_work", @user)
    prompt = @template.build("grade_student_work", data)

    assert_not_nil prompt
    assert prompt.include?(@student_work.assignment.title)
    assert prompt.include?(@student_work.assignment.instructions)
    assert prompt.include?(@student_work.selected_document.title)
  end

  test "builds prompt for assignment summary feedback" do
    data = DataCollectionService.collect(@assignment, "generate_summary_feedback", @user)
    prompt = @template.build("generate_summary_feedback", data)

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
    invalid_erb_content = "Assignment: <%= data[:assignment][:nonexistent_field].some_method %>"

    File.expects(:read).returns(invalid_erb_content)

    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    error = assert_raises(NoMethodError) do
      @template.build("generate_rubric", data)
    end

    assert_match(/undefined method.*some_method.*for nil/, error.message)
  end

  test "interpolates variables correctly in templates" do
    # Mock the file read to return our test template
    test_template_content = "Assignment: <%= data[:assignment][:title] %>\nInstructions: <%= data[:assignment][:instructions] %>"
    File.expects(:read).returns(test_template_content)

    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @template.build("generate_rubric", data)

    assert prompt.include?("Assignment: #{@assignment.title}")
    assert prompt.include?("Instructions: #{@assignment.instructions}")
  end

  test "validates template data before rendering" do
    # Test that the template validates required data fields
    incomplete_data = { process_type: "generate_rubric" }

    error = assert_raises(PromptTemplate::InvalidDataError) do
      @template.build("generate_rubric", incomplete_data)
    end

    assert_match(/Invalid or incomplete data/, error.message)
  end
end
