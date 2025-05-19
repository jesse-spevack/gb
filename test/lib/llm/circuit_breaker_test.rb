require "test_helper"
require_relative "../../../app/lib/llm/client"

class LLM::CircuitBreakerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    # Reset circuit breaker state before each test
    LLM::CircuitBreaker.reset_all
  end

  test "starts in closed state and allows requests" do
    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 5,
      reset_timeout: 30
    )

    assert_equal :closed, breaker.state
    assert breaker.allow_request?
  end

  test "opens circuit after failure threshold is exceeded" do
    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: 30
    )

    # Record failures up to threshold
    3.times { breaker.record_failure }

    # Circuit should now be open
    assert_equal :open, breaker.state
    refute breaker.allow_request?
  end

  test "resets to half-open state after timeout" do
    reset_timeout = 30
    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: reset_timeout
    )

    # Open the circuit
    3.times { breaker.record_failure }
    assert_equal :open, breaker.state
    refute breaker.allow_request?

    # Travel past the reset timeout
    travel reset_timeout + 1 do
      # Now check the state - it should transition to half-open when we check
      assert_equal :half_open, breaker.state
      assert breaker.allow_request?
    end
  end

  test "closes circuit again after successful request in half-open state" do
    reset_timeout = 30
    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: reset_timeout
    )

    # Open the circuit
    3.times { breaker.record_failure }
    assert_equal :open, breaker.state

    # Travel past the reset timeout
    travel reset_timeout + 1 do
      # Should transition to half-open
      assert_equal :half_open, breaker.state
      assert breaker.allow_request?

      # Record a success, which should close the circuit
      breaker.record_success

      # Circuit should now be closed
      assert_equal :closed, breaker.state
      assert breaker.allow_request?
    end
  end

  test "stays open after failure in half-open state" do
    reset_timeout = 30
    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: reset_timeout
    )

    # Open the circuit
    3.times { breaker.record_failure }
    assert_equal :open, breaker.state

    # Travel past the reset timeout
    travel reset_timeout + 1 do
      # Should transition to half-open
      assert_equal :half_open, breaker.state

      # Record another failure, circuit should be open again
      breaker.record_failure

      # Circuit should now be open again
      assert_equal :open, breaker.state
      refute breaker.allow_request?
    end
  end

  test "isolates circuits by provider" do
    anthropic_breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: 30
    )

    google_breaker = LLM::CircuitBreaker.new(
      provider: :google,
      failure_threshold: 3,
      reset_timeout: 30
    )

    # Open anthropic circuit
    3.times { anthropic_breaker.record_failure }

    # Anthropic circuit should be open
    assert_equal :open, anthropic_breaker.state
    refute anthropic_breaker.allow_request?

    # Google circuit should still be closed
    assert_equal :closed, google_breaker.state
    assert google_breaker.allow_request?
  end

  test "notifies about state changes" do
    notifications = []
    reset_timeout = 30

    # Create a test notification handler
    notification_handler = ->(provider, old_state, new_state) {
      notifications << { provider: provider, old_state: old_state, new_state: new_state }
    }

    breaker = LLM::CircuitBreaker.new(
      provider: :anthropic,
      failure_threshold: 3,
      reset_timeout: reset_timeout,
      on_state_change: notification_handler
    )

    # Open the circuit, should trigger notification
    3.times { breaker.record_failure }
    assert_equal 1, notifications.size
    assert_equal :closed, notifications[0][:old_state]
    assert_equal :open, notifications[0][:new_state]

    # Travel past the reset timeout and test the circuit
    travel reset_timeout + 1 do
      # Check the circuit, this should trigger half-open state
      breaker.allow_request?

      # Should have a second notification now (open -> half_open)
      assert_equal 2, notifications.size
      assert_equal :anthropic, notifications[1][:provider]
      assert_equal :open, notifications[1][:old_state]
      assert_equal :half_open, notifications[1][:new_state]
    end
  end

  test "class-level interface provides basic functionality" do
    # Test basic functionality of class-level interface

    # Verify default state allows requests for both providers
    assert LLM::CircuitBreaker.allow_request?(:anthropic), "Anthropic should allow requests by default"
    assert LLM::CircuitBreaker.allow_request?(:google), "Google should allow requests by default"

    # Record a success for each provider
    LLM::CircuitBreaker.record_success(:anthropic)
    LLM::CircuitBreaker.record_success(:google)

    # Reset a breaker
    LLM::CircuitBreaker.reset(:anthropic)

    # Verify both still work after interactions
    assert LLM::CircuitBreaker.allow_request?(:anthropic), "Anthropic should allow requests after reset"
    assert LLM::CircuitBreaker.allow_request?(:google), "Google should still allow requests after success"

    # Create and get the actual breaker instances for direct inspection
    anthropic_breaker = LLM::CircuitBreaker.for_provider(:anthropic)
    google_breaker = LLM::CircuitBreaker.for_provider(:google)

    # Verify they're distinct instances
    refute_equal anthropic_breaker.object_id, google_breaker.object_id, "Breakers should be distinct instances"

    # Verify their initial states
    assert_equal :closed, anthropic_breaker.state, "Anthropic breaker should start closed"
    assert_equal :closed, google_breaker.state, "Google breaker should start closed"
  end

  test "class-level interface correctly opens circuit" do
    # Set known failure threshold
    failure_threshold = 3

    # Create a class-level circuit with custom failure threshold
    provider = :test_provider

    # Create the breaker with an explicit failure threshold to ensure test consistency
    breaker = LLM::CircuitBreaker.for_provider(provider, failure_threshold: failure_threshold)

    # Record failures until threshold is reached
    failure_threshold.times do
      LLM::CircuitBreaker.record_failure(provider)
    end

    # Verify the circuit is now open
    assert_equal :open, breaker.state, "Circuit should be open after failures"
    refute LLM::CircuitBreaker.allow_request?(provider), "Requests should be blocked"

    # Reset and verify it's closed again
    LLM::CircuitBreaker.reset(provider)
    assert_equal :closed, breaker.state, "Circuit should be closed after reset"
    assert LLM::CircuitBreaker.allow_request?(provider), "Requests should be allowed"
  end
end
