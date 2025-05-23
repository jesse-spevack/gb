require "net/http"
require "uri"
require "json"
require_relative "models_config"

module LLM
  class GoogleClient < Client
    BASE_URL = "https://generativelanguage.googleapis.com".freeze
    API_VERSION = "v1beta".freeze

    attr_reader :model

    def initialize(model: nil, temperature: 0.7)
      super(temperature: temperature)
      @model = model || default_model
      validate_api_key!
      validate_model!
    end

    def send_request(prompt)
      response = LLM::CircuitBreaker.run(:google) do
        make_http_request(uri, request(prompt))
      end

      LLMResponse.from_google(response.body)
    end

    def handle_error_response(response, error_data)
      error_message = error_data.dig("error", "message")

      case response.code.to_i
      when 401
        raise AuthenticationError, "Google API authentication failed: #{error_message}"
      when 429
        raise RateLimitError, "Google API rate limit exceeded: #{error_message}"
      when 500..599
        raise ServiceUnavailableError, "Google API service error: #{error_message}"
      else
        raise RequestError, "Google API error (#{response.code}): #{error_message}"
      end
    end

    private

    def request(prompt)
      request = Net::HTTP::Post.new(uri)

      request["Content-Type"] = "application/json"
      request["X-Goog-Api-Key"] = api_key

      request.body = {
        contents: [
          { role: "user", parts: [ { text: prompt } ] }
        ],
        generationConfig: {
          temperature: @temperature,
          maxOutputTokens: 8192
        }
      }.to_json

      request
    end

    def uri
      URI.parse("#{BASE_URL}/#{API_VERSION}/models/#{model}:generateContent")
    end

    def api_key
      ENV["GOOGLE_AI_KEY"]
    end

    def validate_api_key!
      raise AuthenticationError, "Google AI key is missing. Set the GOOGLE_AI_KEY environment variable." unless api_key
    end

    def validate_model!
      available_models = ModelsConfig.model_names_for_provider("google")
      unless available_models.include?(@model)
        raise ArgumentError, "Invalid Google model: #{@model}. Available models: #{available_models.join(', ')}"
      end
    end

    def default_model
      ModelsConfig.default_model_for_provider("google")
    end
  end
end
