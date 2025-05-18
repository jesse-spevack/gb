require "test_helper"

class LLMResponseTest < ActiveSupport::TestCase
  test "initialization sets attributes correctly" do
    response = LLMResponse.new(
      text: "Sample text",
      input_tokens: 10,
      output_tokens: 20,
      model: "test-model",
      raw_response: '{"example": "data"}'
    )

    assert_equal "Sample text", response.text
    assert_equal 10, response.input_tokens
    assert_equal 20, response.output_tokens
    assert_equal "test-model", response.model
    assert_equal '{"example": "data"}', response.raw_response
  end

  test "initialization uses default values for optional attributes" do
    response = LLMResponse.new(text: "Sample text")

    assert_equal "Sample text", response.text
    assert_equal 0, response.input_tokens
    assert_equal 0, response.output_tokens
    assert_nil response.model
    assert_nil response.raw_response
  end

  test "total_tokens returns sum of input and output tokens" do
    response = LLMResponse.new(
      text: "Sample text",
      input_tokens: 10,
      output_tokens: 20
    )

    assert_equal 30, response.total_tokens
  end

  test "from_anthropic parses API response correctly" do
    raw_response = {
      "content" => [
        { "type" => "text", "text" => "First part" },
        { "type" => "text", "text" => "Second part" }
      ],
      "usage" => {
        "input_tokens" => 15,
        "output_tokens" => 25
      },
      "model" => "claude-3-7-sonnet-latest"
    }.to_json

    response = LLMResponse.from_anthropic(raw_response)

    assert_equal "First partSecond part", response.text
    assert_equal 15, response.input_tokens
    assert_equal 25, response.output_tokens
    assert_equal "claude-3-7-sonnet-latest", response.model
    assert_equal raw_response, response.raw_response
  end

  test "from_google parses API response correctly" do
    raw_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "First part" },
              { "text" => "Second part" }
            ]
          }
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 15,
        "candidatesTokenCount" => 25,
        "totalTokenCount" => 40
      },
      "modelVersion" => "gemini-2.5-flash-preview-04-17"
    }.to_json

    response = LLMResponse.from_google(raw_response)

    assert_equal "First partSecond part", response.text
    assert_equal 15, response.input_tokens
    assert_equal 25, response.output_tokens
    assert_equal "gemini-2.5-flash-preview-04-17", response.model
    assert_equal raw_response, response.raw_response
  end

  test "from_anthropic handles missing token usage" do
    raw_response = {
      "content" => [
        { "type" => "text", "text" => "Response with no usage" }
      ],
      "model" => "claude-3-7-sonnet-latest"
    }.to_json

    response = LLMResponse.from_anthropic(raw_response)

    assert_equal "Response with no usage", response.text
    assert_nil response.input_tokens
    assert_nil response.output_tokens
  end

  test "from_google handles missing token usage" do
    raw_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "Response with no usage" }
            ]
          }
        }
      ]
    }.to_json

    response = LLMResponse.from_google(raw_response)

    assert_equal "Response with no usage", response.text
    assert_nil response.input_tokens
    assert_nil response.output_tokens
  end

  test "extract_text_from_anthropic filters and joins text content" do
    data = {
      "content" => [
        { "type" => "text", "text" => "Part 1" },
        { "type" => "image", "source" => { "data" => "base64data" } },
        { "type" => "text", "text" => "Part 2" }
      ]
    }

    result = LLMResponse.extract_text_from_anthropic(data)

    assert_equal "Part 1Part 2", result
  end

  test "extract_text_from_google filters and joins text content" do
    data = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "Part 1" },
              { "other" => "Some other data" },
              { "text" => "Part 2" }
            ]
          }
        }
      ]
    }

    result = LLMResponse.extract_text_from_google(data)

    assert_equal "Part 1Part 2", result
  end

  test "extract_text_from_google handles empty candidates" do
    data = { "candidates" => [] }
    result = LLMResponse.extract_text_from_google(data)
    assert_equal "", result
  end

  test "extract_text_from_google handles missing candidates" do
    data = {}
    result = LLMResponse.extract_text_from_google(data)
    assert_equal "", result
  end
end
