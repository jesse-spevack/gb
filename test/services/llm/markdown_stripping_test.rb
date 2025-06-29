# frozen_string_literal: true

require "test_helper"

class LLM::MarkdownStrippingTest < ActiveSupport::TestCase
  # Test that all LLM response parsers consistently handle markdown-wrapped JSON responses
  # This prevents regression of the issue where LLMs return JSON wrapped in ```json code blocks

  test "rubric generator strips markdown formatting from JSON response" do
    generator = LLM::Rubric::Generator.new(double("context"))

    # Test ```json wrapped response
    json_with_markdown = "```json\n{\"test\": \"value\"}\n```"
    cleaned = generator.send(:strip_markdown_formatting, json_with_markdown)
    assert_equal "{\"test\": \"value\"}", cleaned

    # Test generic ``` wrapped response
    json_with_generic_markdown = "```\n{\"test\": \"value\"}\n```"
    cleaned = generator.send(:strip_markdown_formatting, json_with_generic_markdown)
    assert_equal "{\"test\": \"value\"}", cleaned

    # Test unwrapped JSON (should remain unchanged)
    plain_json = "{\"test\": \"value\"}"
    cleaned = generator.send(:strip_markdown_formatting, plain_json)
    assert_equal "{\"test\": \"value\"}", cleaned
  end

  test "rubric response parser strips markdown formatting from JSON response" do
    context = double("context", llm_response: double("response", text: "```json\n{\"criteria\": []}\n```"))
    parser = LLM::Rubric::ResponseParser.new(context)

    cleaned = parser.send(:strip_markdown_formatting, "```json\n{\"criteria\": []}\n```")
    assert_equal "{\"criteria\": []}", cleaned
  end

  test "student work generator strips markdown formatting from JSON response" do
    generator = LLM::StudentWork::Generator.new(double("context"))

    # Test ```json wrapped response
    json_with_markdown = "```json\n{\"qualitative_feedback\": \"test\"}\n```"
    cleaned = generator.send(:strip_markdown_formatting, json_with_markdown)
    assert_equal "{\"qualitative_feedback\": \"test\"}", cleaned

    # Test generic ``` wrapped response
    json_with_generic_markdown = "```\n{\"qualitative_feedback\": \"test\"}\n```"
    cleaned = generator.send(:strip_markdown_formatting, json_with_generic_markdown)
    assert_equal "{\"qualitative_feedback\": \"test\"}", cleaned
  end

  test "student work response parser strips markdown formatting from JSON response" do
    context = double("context", llm_response: double("response", text: "```json\n{\"qualitative_feedback\": \"test\"}\n```"))
    parser = LLM::StudentWork::ResponseParser.new(context)

    cleaned = parser.send(:strip_markdown_formatting, "```json\n{\"qualitative_feedback\": \"test\"}\n```")
    assert_equal "{\"qualitative_feedback\": \"test\"}", cleaned
  end

  test "assignment summary generator strips markdown formatting from JSON response" do
    generator = LLM::AssignmentSummary::Generator.new(double("context"))

    # Test ```json wrapped response
    json_with_markdown = "```json\n{\"qualitative_insights\": \"test\"}\n```"
    cleaned = generator.send(:strip_markdown_formatting, json_with_markdown)
    assert_equal "{\"qualitative_insights\": \"test\"}", cleaned
  end

  test "assignment summary response parser strips markdown formatting from JSON response" do
    context = double("context", llm_response: double("response", text: "```json\n{\"qualitative_insights\": \"test\"}\n```"))
    parser = LLM::AssignmentSummary::ResponseParser.new(context)

    cleaned = parser.send(:strip_markdown_formatting, "```json\n{\"qualitative_insights\": \"test\"}\n```")
    assert_equal "{\"qualitative_insights\": \"test\"}", cleaned
  end

  test "all parsers handle complex markdown patterns consistently" do
    test_cases = [
      # Standard cases
      [ "```json\n{\"test\": \"value\"}\n```", "{\"test\": \"value\"}" ],
      [ "```\n{\"test\": \"value\"}\n```", "{\"test\": \"value\"}" ],
      [ "{\"test\": \"value\"}", "{\"test\": \"value\"}" ],

      # Edge cases
      [ "```json\n{\"test\": \"value\"}```", "{\"test\": \"value\"}" ],
      [ "```json{\"test\": \"value\"}\n```", "{\"test\": \"value\"}" ],
      [ "  ```json\n{\"test\": \"value\"}\n```  ", "{\"test\": \"value\"}" ],

      # Multiline JSON
      [ "```json\n{\n  \"test\": \"value\",\n  \"other\": \"data\"\n}\n```", "{\n  \"test\": \"value\",\n  \"other\": \"data\"\n}" ]
    ]

    generators = [
      LLM::Rubric::Generator.new(double("context")),
      LLM::StudentWork::Generator.new(double("context")),
      LLM::AssignmentSummary::Generator.new(double("context"))
    ]

    parsers = [
      LLM::Rubric::ResponseParser.new(double("context")),
      LLM::StudentWork::ResponseParser.new(double("context")),
      LLM::AssignmentSummary::ResponseParser.new(double("context"))
    ]

    test_cases.each do |input, expected_output|
      # Test all generators handle the case consistently
      generators.each do |generator|
        result = generator.send(:strip_markdown_formatting, input)
        assert_equal expected_output, result,
          "Generator #{generator.class} failed to properly strip: #{input.inspect}"
      end

      # Test all parsers handle the case consistently
      parsers.each do |parser|
        result = parser.send(:strip_markdown_formatting, input)
        assert_equal expected_output, result,
          "Parser #{parser.class} failed to properly strip: #{input.inspect}"
      end
    end
  end

  private

  def double(name, attributes = {})
    obj = Object.new
    attributes.each do |method, value|
      obj.define_singleton_method(method) { value }
    end
    obj
  end
end
