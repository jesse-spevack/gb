require "test_helper"

class LLMGeneratorPipelineIntegrationTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
    @rubric = rubrics(:english_essay_rubric)
    @student_work = student_works(:student_essay_one)

    stub_llm_responses
  end

  test "rubric generator integrates with pipeline" do
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.prompt = "Generate rubric"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::Rubric::Generator.call(context: context)

      assert result_context.llm_response.present?
      assert result_context.metrics[:tokens_used] == 500
      assert result_context.metrics[:cost_micro_usd] == 225
      assert result_context.metrics["llm_request_ms"] >= 0
    end

    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal @user, usage_record.user
    assert_equal "gemini-2.0-flash-lite", usage_record.llm_model
    assert_equal "google", usage_record.llm_provider
    assert_equal :generate_rubric, usage_record.request_type.to_sym
    assert_equal 500, usage_record.token_count
    assert_equal 225, usage_record.micro_usd
  end

  test "student work generator integrates with pipeline" do
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.rubric = @rubric
    context.user = @user
    context.assignment = @student_work.assignment
    context.prompt = "Analyze student work"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::StudentWork::Generator.call(context: context)

      assert result_context.llm_response.present?
      assert result_context.metrics[:tokens_used] == 800
      assert result_context.metrics[:cost_micro_usd] == 640
    end

    usage_record = LLMUsageRecord.last
    assert_equal @student_work, usage_record.trackable
    assert_equal "claude-3-5-haiku-20241022", usage_record.llm_model
    assert_equal "anthropic", usage_record.llm_provider
    assert_equal :grade_student_work, usage_record.request_type.to_sym
  end

  test "assignment summary generator integrates with pipeline" do
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = @assignment
    context.user = @user
    context.student_feedbacks = []
    context.prompt = "Generate summary"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::AssignmentSummary::Generator.call(context: context)

      assert result_context.llm_response.present?
      assert_equal 1200, result_context.metrics[:tokens_used]
      assert result_context.metrics[:cost_micro_usd] == 640
    end

    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal :generate_assignment_summary, usage_record.request_type.to_sym
  end

  test "generators handle JSON retry in pipeline context" do
    # Override stub to return invalid JSON first
    LLM::GoogleClient.unstub(:generate)

    invalid_response = LLMResponse.new(
      text: "Invalid JSON",
      model: "gemini-2.0-flash-lite",
      input_tokens: 50,
      output_tokens: 50
    )

    valid_response = LLMResponse.new(
      text: valid_rubric_json,
      model: "gemini-2.0-flash-lite",
      input_tokens: 200,
      output_tokens: 300
    )

    LLM::GoogleClient.expects(:generate).twice.returns(invalid_response, valid_response)
    LLM::CostCalculator.stubs(:get_cost).returns(225)
    LLM::CostTracker.stubs(:record)

    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.prompt = "Generate rubric"

    result = LLM::Rubric::Generator.call(context: context)

    assert_equal valid_response, result.llm_response
    assert_equal 1, LLMUsageRecord.count # Only tracks successful request
  end

  test "generators work with pipeline context objects" do
    # Test that generators can work with fully initialized pipeline context
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.prompt = "Generate rubric"

    # Add some existing metrics to verify they're preserved
    context.add_metric("setup_ms", 50)

    result = LLM::Rubric::Generator.call(context: context)

    # Verify existing metrics are preserved
    assert_equal 50, result.metrics["setup_ms"]

    # Verify new metrics were added
    assert result.metrics[:tokens_used] == 500
    assert result.metrics[:cost_micro_usd] == 225
    assert result.metrics.key?("llm_request_ms")
  end

  test "generators preserve context for subsequent pipeline steps" do
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.rubric = @rubric
    context.user = @user
    context.assignment = @student_work.assignment
    context.prompt = "Analyze student work"
    context.add_metric("previous_step_ms", 100)

    result = LLM::StudentWork::Generator.call(context: context)

    # Verify context is preserved
    assert_equal @student_work, result.student_work
    assert_equal @rubric, result.rubric
    assert_equal 100, result.metrics["previous_step_ms"]

    # Verify new metrics were added
    assert result.metrics["llm_request_ms"].present?
    assert result.metrics[:tokens_used].present?
  end

  test "cost tracking works across different providers" do
    # Test Google (Rubric)
    rubric_context = Pipeline::Context::Rubric.new
    rubric_context.assignment = @assignment
    rubric_context.user = @user
    rubric_context.prompt = "Generate rubric"

    LLM::Rubric::Generator.call(context: rubric_context)

    # Test Anthropic (Student Work)
    student_context = Pipeline::Context::StudentWork.new
    student_context.student_work = @student_work
    student_context.user = @user
    student_context.assignment = @student_work.assignment
    student_context.rubric = @rubric
    student_context.prompt = "Analyze work"

    LLM::StudentWork::Generator.call(context: student_context)

    # Verify both were tracked with correct providers
    records = LLMUsageRecord.last(2)

    google_record = records.find { |r| r.llm_provider == "google" }
    anthropic_record = records.find { |r| r.llm_provider == "anthropic" }

    assert google_record.present?
    assert anthropic_record.present?
    assert_equal "gemini-2.0-flash-lite", google_record.llm_model
    assert_equal "claude-3-5-haiku-20241022", anthropic_record.llm_model
  end

  private

  def stub_llm_responses
    # Stub Google client for rubric
    google_response = LLMResponse.new(
      text: valid_rubric_json,
      model: "gemini-2.0-flash-lite",
      input_tokens: 200,
      output_tokens: 300
    )

    LLM::GoogleClient.stubs(:generate).returns(google_response)

    # Stub Anthropic client for student work and summary
    anthropic_student_response = LLMResponse.new(
      text: valid_feedback_json,
      model: "claude-3-5-haiku-20241022",
      input_tokens: 300,
      output_tokens: 500
    )

    anthropic_summary_response = LLMResponse.new(
      text: valid_summary_json,
      model: "claude-3-5-haiku-20241022",
      input_tokens: 700,
      output_tokens: 500
    )

    # Stub different responses based on the prompt content
    LLM::AnthropicClient.stubs(:generate).with { |prompt| prompt.include?("Analyze") }.returns(anthropic_student_response)
    LLM::AnthropicClient.stubs(:generate).with { |prompt| prompt.include?("summary") }.returns(anthropic_summary_response)

    # Stub cost calculator to return specific values for each model
    LLM::CostCalculator.stubs(:get_cost).with { |response| response.model == "gemini-2.0-flash-lite" }.returns(225)
    LLM::CostCalculator.stubs(:get_cost).with { |response| response.model == "claude-3-5-haiku-20241022" }.returns(640)
  end

  def valid_rubric_json
    {
      criteria: [
        {
          title: "Understanding",
          description: "Shows understanding of concepts",
          levels: [
            { title: "Excellent", description: "Complete understanding" },
            { title: "Good", description: "Solid understanding" },
            { title: "Developing", description: "Basic understanding" }
          ]
        }
      ]
    }.to_json
  end

  def valid_feedback_json
    {
      qualitative_feedback: "Good work overall",
      feedback_items: [
        {
          type: "strength",
          title: "Clear writing",
          description: "Well organized thoughts"
        }
      ]
    }.to_json
  end

  def valid_summary_json
    {
      qualitative_insights: "Class performed well overall",
      feedback_items: [
        {
          type: "strength",
          title: "Strong understanding",
          description: "Most students grasp concepts"
        }
      ]
    }.to_json
  end
end
