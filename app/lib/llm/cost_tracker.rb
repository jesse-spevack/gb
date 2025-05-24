require_relative "cost_calculator"

module LLM
  class CostTracker
    class UnknownModelError < LLM::Error; end

    class << self
      def record(llm_response:, trackable:, user:, request_type:, prompt:)
        validate_arguments!(llm_response, trackable, user, request_type, prompt)

        # Calculate cost using existing calculator
        cost_micro_usd = LLM::CostCalculator.get_cost(llm_response)

        # Calculate total tokens
        total_tokens = llm_response.total_tokens

        # Map model to LLM enum value (simplified for now)
        llm_enum_value = map_model_to_enum(llm_response.model)

        # Create and save the LLM usage record
        LLMUsageRecord.create!(
          trackable: trackable,
          user: user,
          llm: llm_enum_value,
          request_type: request_type,
          token_count: total_tokens,
          micro_usd: cost_micro_usd,
          prompt: prompt
        )
      rescue LLM::CostCalculator::UnknownModelError => e
        raise UnknownModelError, e.message
      end

      private

      def validate_arguments!(llm_response, trackable, user, request_type, prompt)
        raise ArgumentError, "llm_response is required" if llm_response.nil?
        raise ArgumentError, "trackable is required" if trackable.nil?
        raise ArgumentError, "user is required" if user.nil?
        raise ArgumentError, "request_type is required" if request_type.nil?
        raise ArgumentError, "prompt is required" if prompt.nil?
      end

      def map_model_to_enum(model_name)
        # Simplified mapping for now - this could be improved later
        # to be more comprehensive or use a different approach
        case model_name
        when /claude/i
          :claude_3_7_sonnet
        when /gemini/i
          :gemini_2_5_pro
        else
          # Default to claude for now, but this will trigger validation
          # in the LLMUsageRecord model if the model is truly unknown
          :claude_3_7_sonnet
        end
      end
    end
  end
end
