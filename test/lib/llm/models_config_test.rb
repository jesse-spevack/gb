require "test_helper"

class LLM::ModelsConfigTest < ActiveSupport::TestCase
  test "returns correct default model for anthropic provider" do
    default_model = LLM::ModelsConfig.default_model_for_provider("anthropic")
    assert_equal "claude-3-5-haiku-20241022", default_model
  end

  test "returns correct default model for google provider" do
    default_model = LLM::ModelsConfig.default_model_for_provider("google")
    assert_equal "gemini-2.0-flash-lite", default_model
  end

  test "can access model config including default field" do
    haiku_config = LLM::ModelsConfig.model_config("claude-3-5-haiku-20241022")
    assert_equal true, haiku_config["default"]
    assert_equal "anthropic", haiku_config["provider"]

    flash_lite_config = LLM::ModelsConfig.model_config("gemini-2.0-flash-lite")
    assert_equal true, flash_lite_config["default"]
    assert_equal "google", flash_lite_config["provider"]
  end

  test "non-default models do not have default field set to true" do
    opus_config = LLM::ModelsConfig.model_config("claude-opus-4-20250514")
    assert_not_equal true, opus_config["default"]

    flash_config = LLM::ModelsConfig.model_config("gemini-2.0-flash")
    assert_not_equal true, flash_config["default"]
  end

  test "returns model names for provider" do
    anthropic_models = LLM::ModelsConfig.model_names_for_provider("anthropic")
    assert_includes anthropic_models, "claude-3-5-haiku-20241022"
    assert_includes anthropic_models, "claude-opus-4-20250514"

    google_models = LLM::ModelsConfig.model_names_for_provider("google")
    assert_includes google_models, "gemini-2.0-flash-lite"
    assert_includes google_models, "gemini-2.0-flash"
  end

  test "validates YAML configuration structure and integrity" do
    # Test 1: YAML loads successfully (malformed YAML would raise an exception)
    assert_nothing_raised do
      LLM::ModelsConfig.models
    end

    # Test 2: All models have required keys
    required_keys = %w[provider display_name input_cost_per_million_tokens output_cost_per_million_tokens context_window description]

    LLM::ModelsConfig.models.each do |model_name, config|
      required_keys.each do |key|
        assert config.key?(key), "Model '#{model_name}' is missing required key '#{key}'"
        assert_not_nil config[key], "Model '#{model_name}' has nil value for required key '#{key}'"
      end

      # Validate data types for critical fields
      assert config["input_cost_per_million_tokens"].is_a?(Numeric), "Model '#{model_name}' input_cost_per_million_tokens must be numeric"
      assert config["output_cost_per_million_tokens"].is_a?(Numeric), "Model '#{model_name}' output_cost_per_million_tokens must be numeric"
      assert config["context_window"].is_a?(Integer), "Model '#{model_name}' context_window must be an integer"
      assert config["provider"].is_a?(String), "Model '#{model_name}' provider must be a string"
      assert config["display_name"].is_a?(String), "Model '#{model_name}' display_name must be a string"
      assert config["description"].is_a?(String), "Model '#{model_name}' description must be a string"
    end

    # Test 3 & 4: Each provider has exactly one default model
    providers = LLM::ModelsConfig.models.values.map { |config| config["provider"] }.uniq

    providers.each do |provider|
      provider_models = LLM::ModelsConfig.models.select { |_, config| config["provider"] == provider }
      default_models = provider_models.select { |_, config| config["default"] == true }

      assert_equal 1, default_models.count,
        "Provider '#{provider}' must have exactly one default model, but has #{default_models.count}. " \
        "Default models: #{default_models.keys.join(', ')}"
    end

    # Test 5: Validate that known providers exist
    expected_providers = %w[anthropic google]
    expected_providers.each do |provider|
      provider_models = LLM::ModelsConfig.model_names_for_provider(provider)
      assert provider_models.any?, "Expected provider '#{provider}' not found in configuration"
    end
  end
end
