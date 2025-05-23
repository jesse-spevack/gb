require "yaml"

module LLM
  module ModelsConfig
    class << self
      def models
        @models ||= YAML.load_file(Rails.root.join("config", "llm_models.yml"))["models"]
      end

      def model_names_for_provider(provider)
        models.select { |_, config| config["provider"] == provider }.keys
      end

      def model_config(model_name)
        models[model_name]
      end

      def default_model_for_provider(provider)
        default_model = models.find { |_, config| config["provider"] == provider && config["default"] == true }
        # Return the model name (first element) from the default model pair if one was found
        # default_model is an array pair like ["gemini-pro", {"provider"=>"google", "default"=>true}]
        default_model[0] if default_model
      end
    end
  end
end
