class LLMResponse
  attr_reader :text, :input_tokens, :output_tokens, :model, :raw_response

  def self.from_anthropic(raw_response)
    data = JSON.parse(raw_response)
    extracted_text = extract_text_from_anthropic(data)

    # Log the extracted text for debugging
    Rails.logger.info("Extracted text from Anthropic response:")
    Rails.logger.info(extracted_text)

    new(
      text: extracted_text,
      input_tokens: data.dig("usage", "input_tokens"),
      output_tokens: data.dig("usage", "output_tokens"),
      model: data["model"],
      raw_response: raw_response
    )
  end

  def self.from_google(raw_response)
    data = JSON.parse(raw_response)
    extracted_text = extract_text_from_google(data)

    # Log the extracted text for debugging
    Rails.logger.info("Extracted text from Google response:")
    Rails.logger.info(extracted_text)

    new(
      text: extracted_text,
      input_tokens: data.dig("usageMetadata", "promptTokenCount"),
      output_tokens: data.dig("usageMetadata", "candidatesTokenCount"),
      model: data["modelVersion"],
      raw_response: raw_response
    )
  end

  def self.extract_text_from_anthropic(data)
    data["content"]
      .select { |c| c["type"] == "text" }
      .map { |c| c["text"] }
      .join
  end

  def self.extract_text_from_google(data)
    return "" if data["candidates"].blank?

    data["candidates"]
      .first
      .dig("content", "parts")
      .to_a
      .select { |part| part.key?("text") }
      .map { |part| part["text"] }
      .join
  end

  def initialize(text:, input_tokens: 0, output_tokens: 0, model: nil, raw_response: nil)
    @text = text
    @input_tokens = input_tokens
    @output_tokens = output_tokens
    @model = model
    @raw_response = raw_response
  end

  def total_tokens
    input_tokens.to_i + output_tokens.to_i
  end
end
