# Top-level module for LLM functionality
module LLM
  # Custom error classes
  class Error < StandardError; end
  class PromptValidationError < Error; end
  class RequestError < Error; end
  class RateLimitError < RequestError; end
  class AuthenticationError < RequestError; end
  class ServiceUnavailableError < RequestError; end
end

# Load all LLM files
Dir[Rails.root.join("app/lib/llm/**/*.rb")].sort.each { |file| require file }
