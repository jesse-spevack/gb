module LLM
  class Error < StandardError; end
  class PromptValidationError < Error; end
  class RequestError < Error; end
  class RateLimitError < RequestError; end
  class AuthenticationError < RequestError; end
  class ServiceUnavailableError < RequestError; end

  class Client
    attr_reader :temperature

    def initialize(temperature: 0.7)
      raise NotImplementedError, "Subclasses of LLM::Client must implement #send_request" unless self.class.method_defined?(:send_request)
      @temperature = temperature
    end

    def self.generate(prompt)
      client = new
      client.validate_prompt(prompt)
      client.send_request(prompt)
    end

    def validate_prompt(prompt)
      raise PromptValidationError, "Prompt cannot be nil" if prompt.nil?
      raise PromptValidationError, "Prompt cannot be empty" if prompt.empty?
    end

    protected

    def make_http_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      begin
        response = LLM::RetryHandler.with_retries do
          http.request(request)
        end

        unless response.code.to_i == 200
          error_data = JSON.parse(response.body) rescue { "error" => { "message" => response.message } }
          handle_error_response(response, error_data)
        end

        response
      rescue StandardError => e
        handle_request_error(e)
      end
    end

    def handle_error_response(response, error_data)
      error_message = error_data.dig("error", "message") || response.message

      case response.code.to_i
      when 401
        raise AuthenticationError, "Authentication failed: #{error_message}"
      when 429
        raise RateLimitError, "Rate limit exceeded: #{error_message}"
      when 500..599
        raise ServiceUnavailableError, "Service error: #{error_message}"
      else
        raise RequestError, "API error (#{response.code}): #{error_message}"
      end
    end

    def handle_request_error(error)
      case error
      when Net::HTTPClientException
        if error.response.code == "401"
          raise AuthenticationError, "Authentication failed: #{error.message}"
        elsif error.response.code == "429"
          raise RateLimitError, "Rate limit exceeded: #{error.message}"
        else
          raise RequestError, "HTTP client error: #{error.message}"
        end
      when Net::HTTPServerError
        raise ServiceUnavailableError, "LLM service error: #{error.message}"
      when Net::HTTPRetriableError
        raise ServiceUnavailableError, "LLM service temporarily unavailable: #{error.message}"
      when Net::OpenTimeout, Net::ReadTimeout
        raise ServiceUnavailableError, "LLM service timeout: #{error.message}"
      else
        raise RequestError, "Error sending request to LLM service: #{error.message}"
      end
    end
  end
end
