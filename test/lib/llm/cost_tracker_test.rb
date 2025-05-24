require "test_helper"

class LLM::CostTrackerTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @assignment = assignments(:english_essay)
    @prompt = "Generate a rubric for this essay assignment"
  end

  test "records cost for Claude response" do
    response = LLMResponse.new(
      text: "Generated rubric content",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-3-5-haiku-20241022"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal @assignment, llm_usage_record.trackable
    assert_equal @user, llm_usage_record.user
    assert_equal "generate_rubric", llm_usage_record.request_type
    assert_equal @prompt, llm_usage_record.prompt
    assert_equal 1500, llm_usage_record.token_count # 1000 + 500
    assert_equal 2800, llm_usage_record.micro_usd # Expected cost for haiku
  end

  test "records cost for Google response" do
    response = LLMResponse.new(
      text: "Generated feedback",
      input_tokens: 2000,
      output_tokens: 800,
      model: "gemini-2.0-flash-lite"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :grade_student_work,
        prompt: @prompt
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal 2800, llm_usage_record.token_count # 2000 + 800
    assert_equal 390, llm_usage_record.micro_usd # Expected cost for gemini
  end

  test "handles zero token responses" do
    response = LLMResponse.new(
      text: "Short response",
      input_tokens: 0,
      output_tokens: 0,
      model: "claude-3-5-haiku-20241022"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal 0, llm_usage_record.token_count
    assert_equal 0, llm_usage_record.micro_usd
  end

  test "handles nil token responses" do
    response = LLMResponse.new(
      text: "Response with nil tokens",
      input_tokens: nil,
      output_tokens: nil,
      model: "claude-3-5-haiku-20241022"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal 0, llm_usage_record.token_count
    assert_equal 0, llm_usage_record.micro_usd
  end

  test "raises error for unknown model" do
    response = LLMResponse.new(
      text: "Response",
      input_tokens: 100,
      output_tokens: 50,
      model: "unknown-model"
    )

    error = assert_raises(LLM::CostTracker::UnknownModelError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    assert_includes error.message, "unknown-model"
  end

  test "raises error for nil model" do
    response = LLMResponse.new(
      text: "Response",
      input_tokens: 100,
      output_tokens: 50,
      model: nil
    )

    error = assert_raises(LLM::CostTracker::UnknownModelError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    assert_includes error.message, "Model cannot be nil"
  end

  test "validates required parameters" do
    response = LLMResponse.new(
      text: "Response",
      input_tokens: 100,
      output_tokens: 50,
      model: "claude-3-5-haiku-20241022"
    )

    assert_raises(ArgumentError) do
      LLM::CostTracker.record(
        llm_response: nil,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    assert_raises(ArgumentError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: nil,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    assert_raises(ArgumentError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: nil,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    assert_raises(ArgumentError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: nil,
        prompt: @prompt
      )
    end

    assert_raises(ArgumentError) do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: nil
      )
    end
  end

  test "works with different trackable types" do
    rubric = rubrics(:english_essay_rubric)
    response = LLMResponse.new(
      text: "Response",
      input_tokens: 500,
      output_tokens: 250,
      model: "claude-3-5-haiku-20241022"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: response,
        trackable: rubric,
        user: @user,
        request_type: :generate_rubric,
        prompt: @prompt
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal rubric, llm_usage_record.trackable
  end
end
