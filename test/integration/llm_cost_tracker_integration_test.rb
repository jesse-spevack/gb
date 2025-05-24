require "test_helper"

class LLMCostTrackerIntegrationTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @assignment = assignments(:english_essay)
  end

  test "full cost tracking workflow with Anthropic response" do
    # Simulate a raw Anthropic API response
    raw_response = {
      "id" => "msg_01WBgmpfVBsW7VbJCyDiRhp2",
      "type" => "message",
      "role" => "assistant",
      "model" => "claude-3-5-haiku-20241022",
      "content" => [
        {
          "type" => "text",
          "text" => "Here is a comprehensive rubric for the essay assignment:\n\n# Essay Rubric\n\n## Content (40%)\n- Clear thesis statement\n- Supporting arguments\n- Evidence and examples\n\n## Organization (30%)\n- Logical structure\n- Smooth transitions\n- Clear introduction and conclusion\n\n## Writing Quality (20%)\n- Grammar and mechanics\n- Sentence variety\n- Appropriate vocabulary\n\n## Creativity (10%)\n- Original insights\n- Engaging presentation"
        }
      ],
      "stop_reason" => "end_turn",
      "stop_sequence" => nil,
      "usage" => {
        "input_tokens" => 1234,
        "output_tokens" => 567
      }
    }.to_json

    # Parse the response using our LLMResponse class
    llm_response = LLMResponse.from_anthropic(raw_response)

    # Verify the response was parsed correctly
    assert_equal "claude-3-5-haiku-20241022", llm_response.model
    assert_equal 1234, llm_response.input_tokens
    assert_equal 567, llm_response.output_tokens
    assert_equal 1801, llm_response.total_tokens
    assert_includes llm_response.text, "Essay Rubric"

    # Track the cost using CostTracker
    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric
      )
    end

    # Verify the usage record was created correctly
    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal @user, usage_record.user
    assert_equal "anthropic", usage_record.llm_provider
    assert_equal "claude-3-5-haiku-20241022", usage_record.llm_model
    assert_equal "generate_rubric", usage_record.request_type
    assert_equal 1801, usage_record.token_count

    # Verify cost calculation (1234 input + 567 output for haiku model)
    # From config: input $0.80/MTok, output $4.00/MTok
    expected_cost = ((1234 * 0.80) + (567 * 4.00)).to_i # input: $0.80/MTok, output: $4.00/MTok
    assert_equal expected_cost, usage_record.micro_usd

    # Verify the dollars method
    expected_dollars = expected_cost.to_f / 1_000_000
    assert_equal expected_dollars, usage_record.dollars
  end

  test "full cost tracking workflow with Google response" do
    # Simulate a raw Google API response
    raw_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "Here is the feedback for the student submission:\n\n## Overall Grade: B+\n\n### Strengths\n- Clear thesis statement\n- Good use of textual evidence\n- Proper essay structure\n\n### Areas for Improvement\n- Could develop arguments more fully\n- Minor grammar issues to address\n\n### Specific Comments\nYour analysis of Macbeth's character development shows good understanding..."
              }
            ]
          },
          "finishReason" => "STOP"
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 2100,
        "candidatesTokenCount" => 850,
        "totalTokenCount" => 2950
      },
      "modelVersion" => "gemini-2.0-flash-lite"
    }.to_json

    # Parse the response using our LLMResponse class
    llm_response = LLMResponse.from_google(raw_response)

    # Verify the response was parsed correctly
    assert_equal "gemini-2.0-flash-lite", llm_response.model
    assert_equal 2100, llm_response.input_tokens
    assert_equal 850, llm_response.output_tokens
    assert_equal 2950, llm_response.total_tokens
    assert_includes llm_response.text, "Overall Grade: B+"

    # Track the cost using CostTracker
    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: @assignment,
        user: @user,
        request_type: :grade_student_work
      )
    end

    # Verify the usage record was created correctly
    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal @user, usage_record.user
    assert_equal "google", usage_record.llm_provider
    assert_equal "gemini-2.0-flash-lite", usage_record.llm_model
    assert_equal "grade_student_work", usage_record.request_type
    assert_equal 2950, usage_record.token_count

    # Verify cost calculation for gemini flash lite
    # From config: input $0.075/MTok, output $0.30/MTok
    expected_cost = ((2100 * 0.075) + (850 * 0.30)).to_i # input: $0.075/MTok, output: $0.30/MTok
    assert_equal expected_cost, usage_record.micro_usd

    # Verify the dollars method
    expected_dollars = expected_cost.to_f / 1_000_000
    assert_equal expected_dollars, usage_record.dollars
  end

  test "cost tracking with different trackable types" do
    rubric = rubrics(:english_essay_rubric)

    llm_response = LLMResponse.new(
      text: "Rubric improvements suggested",
      input_tokens: 800,
      output_tokens: 300,
      model: "claude-3-5-haiku-20241022"
    )

    assert_difference "LLMUsageRecord.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: rubric,
        user: @user,
        request_type: :generate_rubric
      )
    end

    llm_usage_record = LLMUsageRecord.last
    assert_equal rubric, llm_usage_record.trackable
    assert_equal "Rubric", llm_usage_record.trackable_type
  end

  test "cost reporting across multiple requests" do
    # Make several tracked requests
    3.times do |i|
      llm_response = LLMResponse.new(
        text: "Response #{i + 1}",
        input_tokens: 500 + (i * 100),
        output_tokens: 200 + (i * 50),
        model: "claude-3-5-haiku-20241022"
      )

      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric
      )
    end

    # Verify we can query and aggregate data
    assignment_requests = LLMUsageRecord.where(trackable: @assignment)
    assert_equal 3, assignment_requests.count

    user_requests = LLMUsageRecord.where(user: @user)
    assert_operator user_requests.count, :>=, 3

    # Total cost for this assignment
    total_cost_micro_usd = assignment_requests.sum(:micro_usd)
    total_cost_dollars = total_cost_micro_usd.to_f / 1_000_000

    assert_operator total_cost_micro_usd, :>, 0
    assert_operator total_cost_dollars, :>, 0
  end
end
