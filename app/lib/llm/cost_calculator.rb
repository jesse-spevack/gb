require_relative "client"
require_relative "models_config"

module LLM
  class CostCalculator
    class UnknownModelError < LLM::Error; end

    class << self
      def get_cost(llm_response)
        raise UnknownModelError, "Model cannot be nil" if llm_response.model.nil?

        model_config = ModelsConfig.model_config(llm_response.model)
        raise UnknownModelError, "Unknown model: #{llm_response.model}" unless model_config

        input_tokens = llm_response.input_tokens.to_i
        output_tokens = llm_response.output_tokens.to_i

        input_cost_per_token = model_config["input_cost_per_million_tokens"] / 1_000_000.0
        output_cost_per_token = model_config["output_cost_per_million_tokens"] / 1_000_000.0

        total_cost_dollars = (input_tokens * input_cost_per_token) + (output_tokens * output_cost_per_token)

        # Convert to micro_usd (multiply by 1,000,000)
        (total_cost_dollars * 1_000_000).round
      end
    end
  end
end
