require "net/http"
require "uri"
require "json"
require_relative "models_config"

module LLM
  class AnthropicClient < Client
    BASE_URL = "https://api.anthropic.com".freeze
    API_VERSION = "2023-06-01".freeze

    attr_reader :model

    def initialize(model: nil, temperature: 0.7)
      super(temperature: temperature)
      @model = model || default_model
      validate_api_key!
      validate_model!
    end

    def send_request(prompt)
      response = LLM::CircuitBreaker.run(:anthropic) do
        make_http_request(uri, request(prompt))
      end

      # Log the raw Anthropic API response for debugging
      Rails.logger.info("Raw Anthropic API Response Body:")
      Rails.logger.info(response.body)

      LLMResponse.from_anthropic(response.body)
    end

    def handle_error_response(response, error_data)
      error_message = error_data.dig("error", "message")

      case response.code.to_i
      when 401
        raise AuthenticationError, "Anthropic API authentication failed: #{error_message}"
      when 429
        raise RateLimitError, "Anthropic API rate limit exceeded: #{error_message}"
      when 500..599
        raise ServiceUnavailableError, "Anthropic API service error: #{error_message}"
      else
        raise RequestError, "Anthropic API error (#{response.code}): #{error_message}"
      end
    end

    private

    def request(prompt)
      request = Net::HTTP::Post.new(uri)

      request["Content-Type"] = "application/json"
      request["x-api-key"] = api_key
      request["anthropic-version"] = API_VERSION

      request.body = {
        model: @model,
        messages: [ { role: "user", content: prompt } ],
        temperature: @temperature,
        max_tokens: 4096
      }.to_json

      request
    end

    def uri
      URI.parse("#{BASE_URL}/v1/messages")
    end

    def api_key
      ENV["ANTHROPIC_API_KEY"]
    end

    def validate_api_key!
      raise AuthenticationError, "Anthropic API key is missing. Set the ANTHROPIC_API_KEY environment variable." unless api_key
    end

    def validate_model!
      available_models = ModelsConfig.model_names_for_provider("anthropic")
      unless available_models.include?(@model)
        raise ArgumentError, "Invalid Anthropic model: #{@model}. Available models: #{available_models.join(', ')}"
      end
    end

    def default_model
      ModelsConfig.default_model_for_provider("anthropic")
    end
  end
end
