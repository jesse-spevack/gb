require "test_helper"

class LLM::ClientTest < ActiveSupport::TestCase
  class TestClient < LLM::Client
    def send_request(prompt)
      "test response"
    end
  end

  class InvalidClient < LLM::Client
  end

  test "initialize sets default configuration" do
    client = TestClient.new
    assert_equal 0.7, client.temperature
  end

  test "validate_prompt rejects nil prompt" do
    client = TestClient.new

    error = assert_raises(LLM::PromptValidationError) do
      client.validate_prompt(nil)
    end

    assert_equal "Prompt cannot be nil", error.message
  end

  test "validate_prompt rejects empty prompt" do
    client = TestClient.new

    error = assert_raises(LLM::PromptValidationError) do
      client.validate_prompt("")
    end

    assert_equal "Prompt cannot be empty", error.message
  end

  test "validate_prompt accepts valid prompt" do
    client = TestClient.new

    # Should not raise an error
    assert_nothing_raised do
      client.validate_prompt("Valid prompt")
    end
  end

  test "generate calls send_request with validated prompt" do
    client = TestClient
    prompt = "Test prompt"

    result = client.generate(prompt)

    assert_equal "test response", result
  end

  test "must implement send_request" do
    error = assert_raises(NotImplementedError) do
      LLM::Client.new
    end

    assert_equal "Subclasses of LLM::Client must implement #send_request", error.message
  end
end
