require "test_helper"

module LLM
  module AssignmentSummary
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @assignment = assignments(:english_essay)
        @user = users(:teacher)
        @student_feedbacks = [
          { student_work: student_works(:student_essay_one), feedback: "Good work" },
          { student_work: student_works(:student_essay_with_rubric), feedback: "Excellent analysis" }
        ]

        @context = Pipeline::Context::AssignmentSummary.new
        @context.assignment = @assignment
        @context.student_feedbacks = @student_feedbacks
        @context.user = @user
        @context.prompt = "Generate a summary of student performance"
      end

      test "generates summary using Anthropic client" do
        mock_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 700,
          output_tokens: 500
        )

        LLM::AnthropicClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(960) # $0.0096
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_assignment_summary
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 1200, result.metrics[:tokens_used]
        assert_equal 960, result.metrics[:cost_micro_usd]
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "records timing metrics" do
        mock_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 700,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(960)
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert result.metrics.key?("llm_request_ms")
        assert result.metrics["llm_request_ms"].is_a?(Integer)
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = LLMResponse.new(
          text: "This is not valid JSON summary",
          model: "claude-3-5-haiku-20241022",
          input_tokens: 50,
          output_tokens: 50
        )

        valid_json_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 700,
          output_tokens: 500
        )

        # First call returns invalid JSON, second returns valid
        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostCalculator.stubs(:get_cost).returns(960)
        LLM::CostTracker.expects(:record).once

        result = Generator.call(context: @context)

        assert_equal valid_json_response, result.llm_response
      end

      test "fails after second JSON parse error" do
        invalid_response = LLMResponse.new(
          text: "Still not valid JSON",
          model: "claude-3-5-haiku-20241022",
          input_tokens: 50,
          output_tokens: 50
        )

        LLM::AnthropicClient.stubs(:generate).returns(invalid_response)

        assert_raises(JSON::ParserError) do
          Generator.call(context: @context)
        end
      end

      test "calculates cost using CostCalculator" do
        mock_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 1000,
          output_tokens: 1000
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(1600) # $0.016
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 1600, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_assignment_summary_feedback).returns(LLM::AnthropicClient)

        mock_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 700,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(960)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::AnthropicClient.stubs(:generate).raises(LLM::AuthenticationError, "Invalid API key")

        assert_raises(LLM::AuthenticationError) do
          Generator.call(context: @context)
        end
      end

      test "tracks assignment as trackable for cost tracking" do
        mock_response = LLMResponse.new(
          text: valid_summary_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 700,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(960)

        # Assignment summary generator should track against the assignment
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_assignment_summary
        )

        Generator.call(context: @context)
      end

      private

      def valid_summary_json
        {
          qualitative_insights: "Overall, the class demonstrated strong understanding of literary analysis. Most students were able to effectively analyze their chosen books and support their arguments with textual evidence.",
          feedback_items: [
            {
              type: "strength",
              title: "Textual Analysis",
              description: "Students showed excellent ability to analyze themes and characters",
              evidence: "90% of students provided strong textual evidence"
            },
            {
              type: "opportunity",
              title: "Grammar and Mechanics",
              description: "Several students need to focus on proofreading for grammar errors",
              evidence: "Common errors in comma usage and verb tense consistency"
            }
          ],
          performance_summary: {
            strong_performers: 18,
            developing_performers: 10,
            struggling_performers: 2
          }
        }.to_json
      end
    end
  end
end
