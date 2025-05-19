module LLM
  # CircuitBreaker prevents cascading failures by tracking failure rates and
  # temporarily blocking requests to unreliable services.
  #
  # The circuit can be in one of three states:
  # - :closed - normal operation, requests allowed
  # - :open - failure threshold exceeded, requests blocked
  # - :half_open - after timeout, allowing one test request
  #
  # Usage:
  #   # Block-based API (recommended)
  #   result = LLM::CircuitBreaker.run(:anthropic) do
  #     # Make API call to Anthropic
  #     anthropic_client.generate_text(prompt)
  #   end
  #
  #   # Instance API (for advanced use cases)
  #   breaker = LLM::CircuitBreaker.new(provider: :anthropic, failure_threshold: 5)
  #   if breaker.allow_request?
  #     begin
  #       result = make_api_call
  #       breaker.record_success
  #     rescue => e
  #       breaker.record_failure
  #       raise
  #     end
  #   else
  #     # Handle circuit open case
  #   end
  #
  #   # Class API for direct state management
  #   if LLM::CircuitBreaker.allow_request?(:anthropic)
  #     # Make request to Anthropic
  #   end
  class CircuitBreaker
    # Default configuration
    DEFAULT_FAILURE_THRESHOLD = 5
    DEFAULT_RESET_TIMEOUT = 60 # seconds

    # Circuit states
    CLOSED = :closed
    OPEN = :open
    HALF_OPEN = :half_open

    # Class-level storage for circuit breakers by provider
    @breakers = {}
    @mutex = Mutex.new

    class << self
      # Main entry point for circuit breaker protection
      # @param provider [Symbol] The provider name
      # @param options [Hash] Optional circuit breaker configuration
      # @return [Object] The result of the block if successful
      # @raise [StandardError] Any error raised by the block, or CircuitOpenError if circuit is open
      def run(provider, options = {}, &block)
        raise ArgumentError, "Block is required" unless block_given?

        breaker = for_provider(provider, options)

        # Check if circuit allows the request
        unless breaker.allow_request?
          raise CircuitOpenError.new("Circuit is open for provider: #{provider}")
        end

        begin
          # Execute the protected operation
          result = yield

          # Record success
          breaker.record_success

          # Return the result
          result
        rescue => e
          # Record failure
          breaker.record_failure

          # Re-raise the exception
          raise
        end
      end

      # Get or create a circuit breaker for the given provider
      # @param provider [Symbol] The provider name
      # @param options [Hash] Optional configuration for new circuit breakers
      # @return [LLM::CircuitBreaker] The circuit breaker for this provider
      def for_provider(provider, options = {})
        provider_sym = provider.to_sym

        @mutex.synchronize do
          @breakers[provider_sym] ||= begin
            # Create with required keyword argument
            new(provider: provider_sym,
                failure_threshold: options[:failure_threshold] || DEFAULT_FAILURE_THRESHOLD,
                reset_timeout: options[:reset_timeout] || DEFAULT_RESET_TIMEOUT,
                on_state_change: options[:on_state_change])
          end
        end
      end

      # Check if a request is allowed for the provider
      # @param provider [Symbol] The provider name
      # @return [Boolean] Whether a request is allowed
      def allow_request?(provider)
        for_provider(provider).allow_request?
      end

      # Record a success for the provider
      # @param provider [Symbol] The provider name
      def record_success(provider)
        for_provider(provider).record_success
      end

      # Record a failure for the provider
      # @param provider [Symbol] The provider name
      def record_failure(provider)
        for_provider(provider).record_failure
      end

      # Reset the circuit breaker for a specific provider
      # @param provider [Symbol] The provider name
      def reset(provider)
        for_provider(provider).reset
      end

      # Reset all circuit breakers
      def reset_all
        @mutex.synchronize do
          @breakers = {}
        end
      end
    end

    attr_reader :provider, :failure_threshold, :reset_timeout

    # Initialize a new circuit breaker
    # @param provider [Symbol] The provider this circuit breaker is for
    # @param failure_threshold [Integer] Number of failures before opening circuit
    # @param reset_timeout [Integer] Seconds to wait before attempting reset
    # @param on_state_change [Proc] Optional callback for state changes
    def initialize(provider:, failure_threshold: DEFAULT_FAILURE_THRESHOLD,
                  reset_timeout: DEFAULT_RESET_TIMEOUT, on_state_change: nil)
      @provider = provider
      @failure_threshold = failure_threshold
      @reset_timeout = reset_timeout
      @on_state_change = on_state_change

      @state = CLOSED
      @failure_count = 0
      @last_failure_time = nil
      @mutex = Mutex.new
    end

    # Check if the circuit allows a request
    # @return [Boolean] Whether a request is allowed
    def allow_request?
      @mutex.synchronize do
        # First, check if we need to transition state
        check_state_transition

        # Now return based on current state
        case @state
        when CLOSED, HALF_OPEN
          true
        when OPEN
          false
        end
      end
    end

    # Record a successful request
    def record_success
      @mutex.synchronize do
        # If we were in half-open state and had a success, close the circuit
        if @state == HALF_OPEN
          transition_to(CLOSED)
        end

        # Reset failure count in any state
        @failure_count = 0
      end
    end

    # Record a failed request
    def record_failure
      @mutex.synchronize do
        @last_failure_time = Time.now

        case @state
        when CLOSED
          @failure_count += 1
          if @failure_count >= @failure_threshold
            transition_to(OPEN)
          end
        when HALF_OPEN
          # If we get a failure during half-open, go back to open
          transition_to(OPEN)
        when OPEN
          # Already open, just update the failure time
        end
      end
    end

    # Get the current state of the circuit
    # @return [Symbol] The current state (:closed, :open, or :half_open)
    def state
      @mutex.synchronize do
        # Check for potential state transition before returning state
        check_state_transition
        @state
      end
    end

    # Reset the circuit breaker to closed state
    def reset
      @mutex.synchronize do
        @failure_count = 0
        @last_failure_time = nil
        transition_to(CLOSED)
      end
    end

    private

    # Check and apply any necessary state transitions based on timing
    def check_state_transition
      if @state == OPEN && should_transition_to_half_open?
        transition_to(HALF_OPEN)
      end
    end

    # Check if enough time has passed to transition to half-open
    def should_transition_to_half_open?
      @last_failure_time && (Time.now - @last_failure_time >= @reset_timeout)
    end

    # Change the circuit state and trigger the callback if present
    def transition_to(new_state)
      return if @state == new_state

      old_state = @state
      @state = new_state

      # Call the state change callback if provided
      if @on_state_change
        @on_state_change.call(@provider, old_state, new_state)
      end
    end
  end

  # Error raised when a request is attempted with an open circuit
  class CircuitOpenError < StandardError; end
end
