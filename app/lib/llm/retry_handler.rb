require_relative "client"

module LLM
  # Retries failed LLM requests with exponential backoff
  class RetryHandler
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_BASE_DELAY = 1 # second
    DEFAULT_MAX_DELAY = 30 # seconds
    RETRIABLE_ERRORS = [ LLM::RateLimitError, LLM::ServiceUnavailableError ].freeze
    JITTER_PERCENTAGE = 0.2 # 20% jitter

    # Executes a block with automatic retry behavior
    def self.with_retry(**options, &block)
      new(**options).with_retry(&block)
    end

    attr_reader :attempt_logs

    def initialize(max_retries: DEFAULT_MAX_RETRIES,
                  base_delay: DEFAULT_BASE_DELAY,
                  max_delay: DEFAULT_MAX_DELAY,
                  retriable_errors: RETRIABLE_ERRORS)
      @max_retries = max_retries
      @base_delay = base_delay
      @max_delay = max_delay
      @retriable_errors = retriable_errors
      @retries = 0
    end

    def with_retry
      begin
        yield
      rescue StandardError => error
        log_retry_attempt(error)

        if can_retry?(error)
          increment_retry_count
          pause_before_retry
          retry
        end

        raise error
      end
    end

    private

    def retry_count
      @retries
    end

    def increment_retry_count
      @retries += 1
    end

    def can_retry?(error)
      under_retry_limit? && retriable_error?(error) && circuit_allows_retry?
    end

    def under_retry_limit?
      @retries < @max_retries
    end

    def retriable_error?(error)
      @retriable_errors.any? { |err| error.is_a?(err) }
    end

    def circuit_allows_retry?
      !circuit_breaker_open?
    end

    # Placeholder for future circuit breaker integration
    def circuit_breaker_open?
      false
    end

    def pause_before_retry
      sleep(backoff)
    end

    def backoff
      apply_jitter(exponential_delay)
    end

    def exponential_delay
      # Formula: base_delay * 2^(retry_count-1)
      # For retry 1: base_delay * 1
      # For retry 2: base_delay * 2
      # For retry 3: base_delay * 4, etc.
      raw_delay = @base_delay * (2 ** (retry_count - 1))
      [ raw_delay, @max_delay ].min
    end

    def apply_jitter(delay)
      jitter_factor = 1.0 + random_jitter_percentage
      [ delay * jitter_factor, 0 ].max
    end

    def random_jitter_percentage
      (rand * 2 - 1) * JITTER_PERCENTAGE
    end

    def log_retry_attempt(error)
      Rails.logger.warn(
        "[LLM::RetryHandler] Retry #{retry_count + 1} for #{error.class.name}: #{error.message}"
      )
    end
  end
end
