require "test_helper"

module LLM
  module StudentWork
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @student_work = student_works(:student_essay_one)
        @rubric = rubrics(:english_essay_rubric)
        @user = users(:teacher)

        @context = Pipeline::Context::StudentWork.new
        @context.student_work = @student_work
        @context.rubric = @rubric
        @context.user = @user
        @context.assignment = @student_work.assignment
        @context.prompt = "Analyze this student work against the rubric"
      end

      test "generates feedback using Anthropic client" do
        mock_response = LLMResponse.new(
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 300,
          output_tokens: 500
        )

        LLM::AnthropicClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(640) # $0.0064
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @student_work,
          user: @user,
          request_type: :grade_student_work
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 800, result.metrics[:tokens_used]
        assert_equal 640, result.metrics[:cost_micro_usd]
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "records timing metrics" do
        mock_response = LLMResponse.new(
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 300,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(640)
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert result.metrics.key?("llm_request_ms")
        assert result.metrics["llm_request_ms"].is_a?(Integer)
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = LLMResponse.new(
          text: "This is not valid JSON feedback",
          model: "claude-3-5-haiku-20241022",
          input_tokens: 50,
          output_tokens: 50
        )

        valid_json_response = LLMResponse.new(
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 300,
          output_tokens: 500
        )

        # First call returns invalid JSON, second returns valid
        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostCalculator.stubs(:get_cost).returns(640)
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
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 400,
          output_tokens: 600
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(800) # $0.008
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 800, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_student_work_feedback).returns(LLM::AnthropicClient)

        mock_response = LLMResponse.new(
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 300,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(640)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::AnthropicClient.stubs(:generate).raises(LLM::ServiceUnavailableError, "Service temporarily unavailable")

        assert_raises(LLM::ServiceUnavailableError) do
          Generator.call(context: @context)
        end
      end

      test "tracks correct request type for cost tracking" do
        mock_response = LLMResponse.new(
          text: valid_feedback_json,
          model: "claude-3-5-haiku-20241022",
          input_tokens: 300,
          output_tokens: 500
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(640)

        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @student_work,
          user: @user,
          request_type: :grade_student_work
        )

        Generator.call(context: @context)
      end

      private

      def valid_feedback_json
        {
          qualitative_feedback: "The student demonstrates a good understanding of the physics concepts. The explanations are clear and well-structured.",
          feedback_items: [
            {
              type: "strength",
              title: "Clear explanations",
              description: "Student explains concepts using appropriate terminology",
              evidence: "See paragraph 2 where forces are described"
            },
            {
              type: "opportunity",
              title: "Show calculations",
              description: "Include step-by-step calculations for problems",
              evidence: "Problem 3 lacks detailed work"
            }
          ],
          criterion_assessments: [
            {
              criterion_id: "physics_understanding",
              level: "good",
              explanation: "Demonstrates solid grasp of core concepts"
            }
          ]
        }.to_json
      end
    end
  end
end
