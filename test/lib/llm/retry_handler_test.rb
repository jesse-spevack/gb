require "test_helper"

class LLM::RetryHandlerTest < ActiveSupport::TestCase
  test "retries specified number of times and eventually succeeds" do
    call_count = 0

    result = LLM::RetryHandler.with_retries(max_retries: 3, base_delay: 0.01, max_delay: 0.05) do
      call_count += 1

      if call_count < 3
        raise LLM::ServiceUnavailableError, "Service temporarily unavailable"
      end

      "success"
    end

    assert_equal 3, call_count
    assert_equal "success", result
  end

  test "gives up after max retries and raises the last error" do
    call_count = 0

    assert_raises(LLM::ServiceUnavailableError) do
      LLM::RetryHandler.with_retries(max_retries: 2, base_delay: 0.01, max_delay: 0.05) do
        call_count += 1
        raise LLM::ServiceUnavailableError, "Service unavailable"
      end
    end

    assert_equal 3, call_count # initial + 2 retries
  end

  test "doesn't retry for non-retriable errors" do
    call_count = 0

    assert_raises(LLM::PromptValidationError) do
      LLM::RetryHandler.with_retries(max_retries: 3, base_delay: 0.01, max_delay: 0.05) do
        call_count += 1
        raise LLM::PromptValidationError, "Invalid prompt"
      end
    end

    assert_equal 1, call_count # no retries
  end

  test "uses exponential backoff for retry delays" do
    delays = []

    # Capture the delay without actually sleeping
    original_sleep_method = LLM::RetryHandler.instance_method(:sleep)
    LLM::RetryHandler.define_method(:sleep) do |seconds|
      delays << seconds
    end

    begin
      assert_raises(LLM::ServiceUnavailableError) do
        LLM::RetryHandler.with_retries(max_retries: 3, base_delay: 0.1, max_delay: 10) do
          raise LLM::ServiceUnavailableError, "Service unavailable"
        end
      end

      assert_equal 3, delays.length

      # Check that delays increase exponentially (allowing for jitter)
      assert delays[1] > delays[0], "Second delay should be greater than first"
      assert delays[2] > delays[1], "Third delay should be greater than second"

      # Base delay is 0.1, so first retry should be between 0.08 and 0.12 (±20% jitter)
      assert_includes 0.08..0.12, delays[0]

      # Second retry should be around 0.2 (2*base_delay) with jitter
      assert_includes 0.16..0.24, delays[1]

      # Third retry should be around 0.4 (4*base_delay) with jitter
      assert_includes 0.32..0.48, delays[2]
    ensure
      # Restore original sleep method
      LLM::RetryHandler.define_method(:sleep, original_sleep_method)
    end
  end

  test "respects max_delay setting" do
    delays = []

    # Capture the delay without actually sleeping
    original_sleep_method = LLM::RetryHandler.instance_method(:sleep)
    LLM::RetryHandler.define_method(:sleep) do |seconds|
      delays << seconds
      # Don't actually sleep in tests
    end

    begin
      assert_raises(LLM::ServiceUnavailableError) do
        LLM::RetryHandler.with_retries(max_retries: 5, base_delay: 1, max_delay: 2) do
          raise LLM::ServiceUnavailableError, "Service unavailable"
        end
      end

      # All delays should be at most max_delay + jitter
      delays.each do |delay|
        assert delay <= 2.4, "Delay #{delay} exceeds max_delay + 20% jitter"
      end

      # Later delays should hit the max
      assert_in_delta 2, delays.last, 0.4, "Later delays should approach max_delay"
    ensure
      # Restore original sleep method
      LLM::RetryHandler.define_method(:sleep, original_sleep_method)
    end
  end
end
