require "test_helper"

class LLM::AnthropicClientTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_api_key"
    ENV["ANTHROPIC_API_KEY"] = @api_key
    @client = LLM::AnthropicClient

    # Set up Net::HTTP mocks
    @http_mock = mock("http")
    Net::HTTP.stubs(:new).returns(@http_mock)
    @http_mock.stubs(:use_ssl=)
    @http_mock.stubs(:open_timeout=)
    @http_mock.stubs(:read_timeout=)
  end

  teardown do
    ENV.delete("ANTHROPIC_API_KEY")
  end

  test "generate sends properly formatted request" do
    prompt = "Test prompt"
    expected_response = {
      "content" => [ { "type" => "text", "text" => "Test response" } ],
      "model" => "claude-3-7-sonnet-latest",
      "usage" => { "input_tokens" => 5, "output_tokens" => 10 }
    }

    mock_response = mock("response")
    mock_response.stubs(:code).returns("200")
    mock_response.stubs(:body).returns(expected_response.to_json)

    @http_mock.expects(:request).with do |request|
      body = JSON.parse(request.body)

      assert_equal "POST", request.method
      assert_equal "/v1/messages", request.path
      assert_equal "application/json", request["Content-Type"]
      assert_equal @api_key, request["x-api-key"]
      assert_equal "2023-06-01", request["anthropic-version"]
      assert_equal [ { "role" => "user", "content" => prompt } ], body["messages"]

      true
    end.returns(mock_response)

    response = @client.generate(prompt)

    # Test that we get an LLMResponse object with the correct text
    assert_instance_of LLMResponse, response
    assert_equal "Test response", response.text
  end

  test "generate handles API errors" do
    prompt = "Test prompt"

    error_response = mock("response")
    error_response.stubs(:code).returns("429")
    error_response.stubs(:message).returns("Rate limit exceeded")
    error_response.stubs(:body).returns({ "error" => { "message" => "Rate limit exceeded" } }.to_json)

    @http_mock.expects(:request).raises(Net::HTTPClientException.new("Rate limit exceeded", error_response))

    assert_raises(LLM::RateLimitError) do
      @client.generate(prompt)
    end
  end

  test "generate handles authentication errors" do
    prompt = "Test prompt"

    # Create a new client with empty API key
    ENV.delete("ANTHROPIC_API_KEY")

    assert_raises(LLM::AuthenticationError) do
      client = LLM::AnthropicClient.new
    end
  end
end
