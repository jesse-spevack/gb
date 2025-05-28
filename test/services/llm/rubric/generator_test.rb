require "test_helper"

module LLM
  module Rubric
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @assignment = assignments(:english_essay)
        @user = users(:teacher)
        @context = Pipeline::Context::Rubric.new
        @context.assignment = @assignment
        @context.user = @user
        @context.prompt = "Generate a rubric for physics assignment"
      end

      test "generates rubric using Google client" do
        mock_response = LLMResponse.new(
          text: valid_rubric_json,
          model: "gemini-2.0-flash-lite",
          input_tokens: 100,
          output_tokens: 400
        )

        LLM::GoogleClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(225) # $0.00225
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_rubric
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 500, result.metrics[:tokens_used]
        assert_equal 225, result.metrics[:cost_micro_usd]
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "records timing metrics" do
        mock_response = LLMResponse.new(
          text: valid_rubric_json,
          model: "gemini-2.0-flash-lite",
          input_tokens: 200,
          output_tokens: 300
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(225) # $0.00225
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        # Check metrics are present
        assert result.metrics.key?("llm_request_ms"), "Expected llm_request_ms metric, got: #{result.metrics.keys}"
        assert result.metrics["llm_request_ms"].is_a?(Integer)
        assert result.metrics["llm_request_ms"] >= 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = LLMResponse.new(
          text: "This is not valid JSON",
          model: "gemini-2.0-flash-lite",
          input_tokens: 50,
          output_tokens: 50
        )

        valid_json_response = LLMResponse.new(
          text: valid_rubric_json,
          model: "gemini-2.0-flash-lite",
          input_tokens: 200,
          output_tokens: 300
        )

        # First call returns invalid JSON, second returns valid
        LLM::GoogleClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::GoogleClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostCalculator.stubs(:get_cost).returns(225)
        LLM::CostTracker.expects(:record).once

        result = Generator.call(context: @context)

        assert_equal valid_json_response, result.llm_response
      end

      test "fails after second JSON parse error" do
        invalid_response = LLMResponse.new(
          text: "Still not valid JSON",
          model: "gemini-2.0-flash-lite",
          input_tokens: 50,
          output_tokens: 50
        )

        LLM::GoogleClient.stubs(:generate).returns(invalid_response)

        assert_raises(JSON::ParserError) do
          Generator.call(context: @context)
        end
      end

      test "calculates cost using CostCalculator" do
        mock_response = LLMResponse.new(
          text: valid_rubric_json,
          model: "gemini-2.0-flash-lite",
          input_tokens: 400,
          output_tokens: 600
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(1500) # $0.015
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 1500, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_rubric_generation).returns(LLM::GoogleClient)

        mock_response = LLMResponse.new(
          text: valid_rubric_json,
          model: "gemini-2.0-flash-lite",
          input_tokens: 200,
          output_tokens: 300
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.stubs(:get_cost).returns(225)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::GoogleClient.stubs(:generate).raises(LLM::RateLimitError, "Rate limit exceeded")

        assert_raises(LLM::RateLimitError) do
          Generator.call(context: @context)
        end
      end

      private

      def valid_rubric_json
        {
          criteria: [
            {
              title: "Understanding",
              description: "Demonstrates understanding of key concepts",
              levels: [
                { title: "Excellent", description: "Shows deep understanding" },
                { title: "Good", description: "Shows solid understanding" },
                { title: "Developing", description: "Shows basic understanding" }
              ]
            }
          ]
        }.to_json
      end
    end
  end
end
