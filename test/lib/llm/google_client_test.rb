require "test_helper"

class LLM::GoogleClientTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_api_key"
    ENV["GOOGLE_AI_KEY"] = @api_key
    @client = LLM::GoogleClient.new

    # Set up Net::HTTP mocks
    @http_mock = mock("http")
    Net::HTTP.stubs(:new).returns(@http_mock)
    @http_mock.stubs(:use_ssl=)
    @http_mock.stubs(:open_timeout=)
    @http_mock.stubs(:read_timeout=)
  end

  teardown do
    ENV.delete("GOOGLE_AI_KEY")
  end

  test "initializes with default config" do
    assert_equal "gemini-2.0-flash-lite", @client.model
  end

  test "initializes with custom model" do
    client = LLM::GoogleClient.new(model: "gemini-2.5-flash-preview-04-17")
    assert_equal "gemini-2.5-flash-preview-04-17", client.model
  end

  test "validates model names from config" do
    client = LLM::GoogleClient.new(model: "gemini-2.0-flash")
    assert_equal "gemini-2.0-flash", client.model

    client = LLM::GoogleClient.new(model: "gemini-2.5-flash-preview-04-17")
    assert_equal "gemini-2.5-flash-preview-04-17", client.model
  end

  test "raises error for invalid model" do
    assert_raises(ArgumentError) do
      LLM::GoogleClient.new(model: "invalid-model")
    end
  end

  test "environment variable is used for API key" do
    custom_key = "custom_api_key"
    ENV["GOOGLE_AI_KEY"] = custom_key

    # Indirectly test that the API key is being used by verifying headers in request
    mock_response = mock("response")
    mock_response.stubs(:code).returns("200")
    mock_response.stubs(:body).returns('{"candidates":[{"content":{"parts":[{"text":"Test"}]}}],"modelVersion":"gemini-2.0-flash-lite"}')

    @http_mock.expects(:request).with do |request|
      assert_equal custom_key, request["X-Goog-Api-Key"]
      true
    end.returns(mock_response)

    @client.send_request("Test")
  end

  test "initializes raises error with missing API key" do
    ENV.delete("GOOGLE_AI_KEY")
    assert_raises(LLM::AuthenticationError) do
      LLM::GoogleClient.new
    end
  end

  test "send_request formats request and returns LLMResponse" do
    prompt = "Test prompt"
    response_body = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "This is a test response" }
            ]
          }
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 10,
        "candidatesTokenCount" => 20,
        "totalTokenCount" => 30
      },
      "modelVersion" => "gemini-2.0-flash-lite"
    }

    mock_response = mock("response")
    mock_response.stubs(:code).returns("200")
    mock_response.stubs(:body).returns(response_body.to_json)

    @http_mock.expects(:request).with do |request|
      body = JSON.parse(request.body)

      assert_equal "POST", request.method
      assert_match /\/v1beta\/models\/gemini-2.0-flash-lite:generateContent/, request.path
      assert_equal "application/json", request["Content-Type"]
      assert_equal @api_key, request["X-Goog-Api-Key"]
      assert_equal "user", body["contents"].first["role"]
      assert_equal prompt, body["contents"].first["parts"].first["text"]

      true
    end.returns(mock_response)

    response = @client.send_request(prompt)

    assert_instance_of LLMResponse, response
    assert_equal "This is a test response", response.text
    assert_equal 10, response.input_tokens
    assert_equal 20, response.output_tokens
    assert_equal "gemini-2.0-flash-lite", response.model
  end

  test "handles API error responses" do
    prompt = "Test prompt"
    error_response = {
      "error" => {
        "code" => 400,
        "message" => "Invalid request",
        "status" => "INVALID_ARGUMENT"
      }
    }

    mock_response = mock("response")
    mock_response.stubs(:code).returns("400")
    mock_response.stubs(:body).returns(error_response.to_json)

    @http_mock.expects(:request).returns(mock_response)

    error = assert_raises LLM::RequestError do
      @client.send_request(prompt)
    end

    assert_match /Google API error/, error.message
    assert_match /Invalid request/, error.message
  end
end
