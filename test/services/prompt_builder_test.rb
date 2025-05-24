require "test_helper"

class PromptBuilderTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
    @builder = PromptBuilder.new
  end

  test "builds prompt for rubric generation" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @builder.build("generate_rubric", data)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
    assert prompt.include?(@assignment.grade_level)
  end

  test "builds prompt for student work grading" do
    data = DataCollectionService.collect(@student_work, "grade_student_work", @user)
    prompt = @builder.build("grade_student_work", data)

    assert_not_nil prompt
    assert prompt.include?(@student_work.assignment.title)
    assert prompt.include?(@student_work.assignment.instructions)
    assert prompt.include?(@student_work.selected_document.title)
  end

  test "builds prompt for assignment summary feedback" do
    data = DataCollectionService.collect(@assignment, "generate_summary_feedback", @user)
    prompt = @builder.build("generate_summary_feedback", data)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
  end

  test "validates prompt length is reasonable" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    prompt = @builder.build("generate_rubric", data)

    # Should have reasonable prompt length (not empty, not excessively long)
    assert prompt.length > 100, "Prompt should have substantial content"
    assert prompt.length < 10000, "Prompt should not be excessively long"
  end

  test "logs prompt generation events" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # Test that logging occurs without asserting specific expectations
    Rails.logger.expects(:info).at_least_once

    prompt = @builder.build("generate_rubric", data)
    assert_not_nil prompt
  end

  test "handles template errors gracefully" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # Mock the template to raise an error
    mock_template = mock()
    mock_template.expects(:build).raises(Errno::ENOENT, "No such file or directory")
    @builder.instance_variable_set(:@template, mock_template)

    error = assert_raises(PromptBuilder::PromptGenerationError) do
      @builder.build("generate_rubric", data)
    end

    assert_match(/Failed to generate prompt/, error.message)
    assert_match(/No such file or directory/, error.message)
  end

  test "provides helper for quick prompt building" do
    # Test convenience method that combines data collection and prompt building
    prompt = @builder.build_for_assignment(@assignment, "generate_rubric", @user)

    assert_not_nil prompt
    assert prompt.include?(@assignment.title)
    assert prompt.include?(@assignment.instructions)
  end

  test "provides helper for student work prompt building" do
    # Test convenience method for student work prompts
    prompt = @builder.build_for_student_work(@student_work, @user)

    assert_not_nil prompt
    assert prompt.include?(@student_work.assignment.title)
    assert prompt.include?(@student_work.selected_document.title)
  end

  test "validates data context before building" do
    # Test that builder validates data context matches process type
    assignment_data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    error = assert_raises(PromptBuilder::InvalidContextError) do
      @builder.build("grade_student_work", assignment_data)
    end

    assert_match(/Invalid data context/, error.message)
  end

  test "adds metadata to generated prompts" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)
    result = @builder.build_with_metadata("generate_rubric", data)

    assert result.is_a?(Hash)
    assert_not_nil result[:prompt]
    assert_not_nil result[:metadata]
    assert_equal "generate_rubric", result[:metadata][:process_type]
    assert_not_nil result[:metadata][:generated_at]
    assert_not_nil result[:metadata][:prompt_length]
  end

  test "caches prompt templates efficiently" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # First call should create template
    first_prompt = @builder.build("generate_rubric", data)

    # Second call should use cached template
    second_prompt = @builder.build("generate_rubric", data)

    assert_equal first_prompt, second_prompt
  end
end
