# frozen_string_literal: true

module LLM
  module StudentWork
    class Generator
      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
        @client = LLM::ClientFactory.for_student_work_feedback
      end

      def call
        response = @context.record_timing(:llm_request) do
          make_llm_request(@context.prompt)
        end

        track_cost(response)
        update_context(response)

        @context
      end

      private

      def make_llm_request(prompt)
        response = @client.generate(prompt)
        validate_json_response(response)
        response
      rescue JSON::ParserError => e
        # One retry with instruction to fix JSON
        Rails.logger.warn "Invalid JSON response for student work feedback, retrying: #{e.message}"
        response = @client.generate(prompt + "\n\nPlease ensure the response is valid JSON.")
        validate_json_response(response)
        response
      end

      def validate_json_response(response)
        JSON.parse(response.text)
      end

      def track_cost(response)
        cost_micro_usd = LLM::CostCalculator.get_cost(response)

        LLM::CostTracker.record(
          llm_response: response,
          trackable: @context.student_work,
          user: @context.user,
          request_type: :grade_student_work
        )

        @context.add_metric(:cost_micro_usd, cost_micro_usd)
      end

      def update_context(response)
        @context.llm_response = response
        @context.add_metric(:tokens_used, response.total_tokens)
      end
    end
  end
end
