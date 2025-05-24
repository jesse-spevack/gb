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
          "text" => "Here is a comprehensive rubric for the essay assignment:\n\n# Essay Rubric\n\n## Content (40%)\n- Clear thesis statement\n- Supporting arguments\n- Evidence and examples\n\n## Organization (30%)\n- Logical structure\n- Smooth transitions\n- Clear introduction and conclusion\n\n## Language (30%)\n- Grammar and mechanics\n- Vocabulary usage\n- Writing style"
        }
      ],
      "stop_reason" => "end_turn",
      "stop_sequence" => nil,
      "usage" => {
        "input_tokens" => 1250,
        "output_tokens" => 420
      }
    }.to_json

    # Create LLMResponse from API response
    llm_response = LLMResponse.from_anthropic(raw_response)

    # Prepare tracking data
    prompt = "Generate a detailed rubric for evaluating student essays in the English class assignment about climate change impacts."

    # Track the cost
    assert_difference "LLMRequest.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: @assignment,
        user: @user,
        request_type: :generate_rubric,
        prompt: prompt
      )
    end

    # Verify the recorded data
    llm_request = LLMRequest.last
    assert_equal @assignment, llm_request.trackable
    assert_equal @user, llm_request.user
    assert_equal "claude_3_7_sonnet", llm_request.llm # Maps claude models to this enum
    assert_equal "generate_rubric", llm_request.request_type
    assert_equal prompt, llm_request.prompt
    assert_equal 1670, llm_request.token_count # 1250 + 420
    assert_operator llm_request.micro_usd, :>, 0 # Should have calculated a cost
    assert_operator llm_request.dollars, :>, 0 # Should convert to dollars
  end

  test "full cost tracking workflow with Google response" do
    # Simulate a raw Google API response
    raw_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "Based on the student's essay, here is the grading feedback:\n\n**Grade: B+**\n\n**Strengths:**\n- Clear thesis statement addressing climate change impacts\n- Good use of scientific evidence\n- Well-organized structure\n\n**Areas for improvement:**\n- Could include more specific examples\n- Some transitions could be smoother\n- Citation format needs attention\n\n**Overall:** A solid essay that demonstrates understanding of the topic with room for refinement in supporting details."
              }
            ]
          },
          "finishReason" => "STOP",
          "index" => 0,
          "safetyRatings" => []
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 2100,
        "candidatesTokenCount" => 380,
        "totalTokenCount" => 2480
      },
      "modelVersion" => "gemini-2.0-flash-lite"
    }.to_json

    # Create LLMResponse from API response
    llm_response = LLMResponse.from_google(raw_response)

    # Prepare tracking data
    prompt = "Please grade this student essay and provide detailed feedback on strengths and areas for improvement."

    # Track the cost
    assert_difference "LLMRequest.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: @assignment,
        user: @user,
        request_type: :grade_student_work,
        prompt: prompt
      )
    end

    # Verify the recorded data
    llm_request = LLMRequest.last
    assert_equal @assignment, llm_request.trackable
    assert_equal @user, llm_request.user
    assert_equal "gemini_2_5_pro", llm_request.llm # Maps gemini models to this enum
    assert_equal "grade_student_work", llm_request.request_type
    assert_equal prompt, llm_request.prompt
    assert_equal 2480, llm_request.token_count # 2100 + 380
    assert_operator llm_request.micro_usd, :>, 0 # Should have calculated a cost
    assert_operator llm_request.dollars, :>, 0 # Should convert to dollars
  end

  test "cost tracking with different trackable types" do
    rubric = rubrics(:english_essay_rubric)

    llm_response = LLMResponse.new(
      text: "Rubric improvements suggested",
      input_tokens: 800,
      output_tokens: 300,
      model: "claude-3-5-haiku-20241022"
    )

    prompt = "Suggest improvements to this rubric for better assessment clarity."

    assert_difference "LLMRequest.count", 1 do
      LLM::CostTracker.record(
        llm_response: llm_response,
        trackable: rubric,
        user: @user,
        request_type: :generate_rubric,
        prompt: prompt
      )
    end

    llm_request = LLMRequest.last
    assert_equal rubric, llm_request.trackable
    assert_equal "Rubric", llm_request.trackable_type
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
        request_type: :generate_rubric,
        prompt: "Test prompt #{i + 1}"
      )
    end

    # Verify we can query and aggregate data
    assignment_requests = LLMRequest.where(trackable: @assignment)
    assert_equal 3, assignment_requests.count

    user_requests = LLMRequest.where(user: @user)
    assert_operator user_requests.count, :>=, 3

    # Total cost for this assignment
    total_cost_micro_usd = assignment_requests.sum(:micro_usd)
    total_cost_dollars = total_cost_micro_usd.to_f / 1_000_000

    assert_operator total_cost_micro_usd, :>, 0
    assert_operator total_cost_dollars, :>, 0
  end
end
