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
        model_name, _config = models.find { |_, config| config["provider"] == provider && config["default"] == true }
        model_name
      end
    end
  end
end
