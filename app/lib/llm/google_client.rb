require "net/http"
require "uri"
require "json"

module LLM
  class GoogleClient < Client
    # API endpoint for Gemini
    BASE_URL = "https://generativelanguage.googleapis.com".freeze
    API_VERSION = "v1beta".freeze
    MODELS = {
      "flash-2-0" => "gemini-2.0-flash",
      "flash-2-5" => "gemini-2.5-flash-preview-04-17"
    }.freeze
    DEFAULT_MODEL = MODELS["flash-2-0"]

    attr_reader :model

    def initialize(model: DEFAULT_MODEL, temperature: 0.7)
      super(temperature: temperature)
      @model = model
      validate_api_key!
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
  end
end
