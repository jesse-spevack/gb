require_relative "cost_calculator"
require_relative "models_config"

module LLM
  class CostTracker
    class UnknownModelError < LLM::Error; end

    class << self
      def record(llm_response:, trackable:, user:, request_type:)
        validate_arguments!(llm_response, trackable, user, request_type)

        # Calculate cost using existing calculator
        cost_micro_usd = LLM::CostCalculator.get_cost(llm_response)

        # Calculate total tokens
        total_tokens = llm_response.total_tokens

        # Map model to provider enum value
        llm_provider = map_model_to_provider(llm_response.model)

        # Create and save the LLM usage record
        LLMUsageRecord.create!(
          trackable: trackable,
          user: user,
          llm_provider: llm_provider,
          llm_model: llm_response.model,
          request_type: request_type,
          token_count: total_tokens,
          micro_usd: cost_micro_usd
        )
      rescue LLM::CostCalculator::UnknownModelError => e
        raise UnknownModelError, e.message
      end

      private

      def validate_arguments!(llm_response, trackable, user, request_type)
        raise ArgumentError, "llm_response is required" if llm_response.nil?
        raise ArgumentError, "trackable is required" if trackable.nil?
        raise ArgumentError, "user is required" if user.nil?
        raise ArgumentError, "request_type is required" if request_type.nil?
      end

      def map_model_to_provider(model_name)
        raise UnknownModelError, "Model cannot be nil" if model_name.nil?

        # Look up the model in the centralized config
        model_config = LLM::ModelsConfig.model_config(model_name)

        if model_config.nil?
          raise UnknownModelError, "Unknown model: #{model_name}"
        end

        provider = model_config["provider"]

        case provider
        when "anthropic"
          :anthropic
        when "google"
          :google
        else
          raise UnknownModelError, "Unsupported provider '#{provider}' for model: #{model_name}"
        end
      end
    end
  end
end
