require "test_helper"

class LLM::StudentWork::ResponseParserTest < ActiveSupport::TestCase
  setup do
    @valid_json = {
      qualitative_feedback: "The student demonstrates a strong understanding of the main concepts. The argument is well-structured with clear evidence supporting the thesis.",
      feedback_items: [
        {
          item_type: "strength",
          title: "Clear Thesis Statement",
          description: "The essay opens with a well-defined thesis that guides the entire argument",
          evidence: "In the introduction, the student states: 'The industrial revolution fundamentally transformed society...'"
        },
        {
          item_type: "opportunity",
          title: "Citation Format",
          description: "Some citations are not properly formatted according to MLA guidelines",
          evidence: "Several in-text citations lack page numbers, such as (Smith) instead of (Smith 45)"
        }
      ],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: 3,
          explanation: "The argument is strong with good supporting evidence throughout the essay"
        },
        {
          criterion_id: 2,
          level_id: 2,
          explanation: "Organization is basic but could benefit from stronger transitions between paragraphs"
        }
      ],
      checks: [
        {
          check_type: "plagiarism",
          score: 15,
          explanation: "Low plagiarism score indicates original work with proper citations"
        },
        {
          check_type: "llm_generated",
          score: 8,
          explanation: "Very low AI-generated content score, appears to be authentic student work"
        }
      ]
    }.to_json

    @llm_response = LLMResponse.new(text: @valid_json)
    @context = Pipeline::Context::StudentWork.new
    @context.student_work = student_works(:student_essay_one)
    @context.llm_response = @llm_response
  end

  test "parses valid JSON with complete student feedback data" do
    result = LLM::StudentWork::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    assert_equal "The student demonstrates a strong understanding of the main concepts. The argument is well-structured with clear evidence supporting the thesis.",
                 result.parsed_response.qualitative_feedback

    # Check feedback items
    assert_equal 2, result.parsed_response.feedback_items.size

    first_item = result.parsed_response.feedback_items.first
    assert_equal "strength", first_item.item_type
    assert_equal "Clear Thesis Statement", first_item.title
    assert_equal "The essay opens with a well-defined thesis that guides the entire argument", first_item.description
    assert_match(/industrial revolution/, first_item.evidence)

    # Check criterion levels
    assert_equal 2, result.parsed_response.criterion_levels.size
    first_level = result.parsed_response.criterion_levels.first
    assert_equal 1, first_level.criterion_id
    assert_equal 3, first_level.level_id
    assert_equal "The argument is strong with good supporting evidence throughout the essay", first_level.explanation

    # Check checks
    assert_equal 2, result.parsed_response.checks.size
    first_check = result.parsed_response.checks.first
    assert_equal "plagiarism", first_check.check_type
    assert_equal 15, first_check.score
    assert_equal "Low plagiarism score indicates original work with proper citations", first_check.explanation
  end

  test "raises JSON::ParserError for invalid JSON" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    assert_raises(JSON::ParserError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
  end

  test "raises error for missing qualitative_feedback field" do
    json = {
      feedback_items: [],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/qualitative_feedback/, error.message)
  end

  test "raises error for invalid feedback_items missing type" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [
        {
          title: "Missing Type",
          description: "This item has no type",
          evidence: "Some evidence"
        }
      ],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/item_type/, error.message)
  end

  test "raises error for invalid feedback_items missing title" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [
        {
          item_type: "strength",
          description: "This item has no title",
          evidence: "Some evidence"
        }
      ],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/title/, error.message)
  end

  test "raises error for invalid feedback_items missing description" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [
        {
          item_type: "strength",
          title: "Some Title",
          evidence: "Some evidence"
        }
      ],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/description/, error.message)
  end

  test "raises error for invalid feedback_items missing evidence" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [
        {
          item_type: "strength",
          title: "Some Title",
          description: "Some description"
        }
      ],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/evidence/, error.message)
  end

  test "raises error for invalid item_type values" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [
        {
          item_type: "invalid_type",
          title: "Some Title",
          description: "Some description",
          evidence: "Some evidence"
        }
      ],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/item_type.*strength.*opportunity/, error.message)
  end

  test "raises error for missing criterion_levels array" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/criterion_levels/, error.message)
  end

  test "raises error for invalid criterion_id (non-integer)" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [
        {
          criterion_id: "not_an_integer",
          level_id: 1,
          explanation: "Some explanation"
        }
      ],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/criterion_id.*integer/, error.message)
  end

  test "raises error for invalid level_id (non-integer)" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: "not_an_integer",
          explanation: "Some explanation"
        }
      ],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/level_id.*integer/, error.message)
  end

  test "raises error for missing explanation in criterion_levels" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: 2
        }
      ],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/explanation/, error.message)
  end

  test "raises error for invalid checks array missing type" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          score: 50,
          explanation: "Missing type"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/check_type/, error.message)
  end

  test "raises error for invalid checks array missing score" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          explanation: "Missing score"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/score/, error.message)
  end

  test "raises error for invalid checks array missing explanation" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          score: 50
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/explanation/, error.message)
  end

  test "raises error for invalid check_type values" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "invalid_type",
          score: 50,
          explanation: "Some explanation"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/check_type.*plagiarism.*llm_generated/, error.message)
  end

  test "raises error for score out of range (below 0)" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          score: -5,
          explanation: "Negative score"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/score.*0.*100/, error.message)
  end

  test "raises error for score out of range (above 100)" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          score: 150,
          explanation: "Score too high"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/score.*0.*100/, error.message)
  end

  test "parsed response is added to context" do
    result = LLM::StudentWork::ResponseParser.call(context: @context)

    assert_same @context, result
    assert_not_nil @context.parsed_response
  end

  test "dot notation access works for nested structures" do
    result = LLM::StudentWork::ResponseParser.call(context: @context)
    parsed = result.parsed_response

    assert_equal "The student demonstrates a strong understanding of the main concepts. The argument is well-structured with clear evidence supporting the thesis.",
                 parsed.qualitative_feedback
    assert_equal "strength", parsed.feedback_items[0].item_type
    assert_equal "Clear Thesis Statement", parsed.feedback_items[0].title
    assert_equal 1, parsed.criterion_levels[0].criterion_id
    assert_equal "plagiarism", parsed.checks[0].check_type
    assert_equal 15, parsed.checks[0].score
  end

  test "handles empty arrays gracefully" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::StudentWork::ResponseParser.call(context: @context)

    assert_equal 0, result.parsed_response.feedback_items.size
    assert_equal 0, result.parsed_response.criterion_levels.size
    assert_equal 0, result.parsed_response.checks.size
  end

  test "string sanitization trims whitespace" do
    json = {
      qualitative_feedback: "  Feedback with whitespace  \n",
      feedback_items: [
        {
          item_type: "strength",
          title: "\tTabbed Title\t",
          description: "  Spaced description  ",
          evidence: "\nEvidence with newlines\n"
        }
      ],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: 2,
          explanation: "  Explanation with spaces  "
        }
      ],
      checks: [
        {
          check_type: "plagiarism",
          score: 20,
          explanation: "\tTabbed explanation\t"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::StudentWork::ResponseParser.call(context: @context)

    assert_equal "Feedback with whitespace", result.parsed_response.qualitative_feedback
    assert_equal "Tabbed Title", result.parsed_response.feedback_items.first.title
    assert_equal "Spaced description", result.parsed_response.feedback_items.first.description
    assert_equal "Evidence with newlines", result.parsed_response.feedback_items.first.evidence
    assert_equal "Explanation with spaces", result.parsed_response.criterion_levels.first.explanation
    assert_equal "Tabbed explanation", result.parsed_response.checks.first.explanation
  end

  test "ignores extra unexpected fields" do
    json = {
      qualitative_feedback: "Some feedback",
      extra_top_level: "should be ignored",
      feedback_items: [
        {
          item_type: "strength",
          title: "Title",
          description: "Description",
          evidence: "Evidence",
          extra_field: "should be ignored"
        }
      ],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: 2,
          explanation: "Explanation",
          another_extra: "also ignored"
        }
      ],
      checks: [
        {
          check_type: "plagiarism",
          score: 20,
          explanation: "Explanation",
          yet_another_extra: "ignored too"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::StudentWork::ResponseParser.call(context: @context)

    assert_respond_to result.parsed_response, :qualitative_feedback
    assert_not_respond_to result.parsed_response, :extra_top_level
    assert_not_respond_to result.parsed_response.feedback_items.first, :extra_field
    assert_not_respond_to result.parsed_response.criterion_levels.first, :another_extra
    assert_not_respond_to result.parsed_response.checks.first, :yet_another_extra
  end

  test "validates score is a number" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          score: "not_a_number",
          explanation: "Score is not numeric"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/score.*number/, error.message)
  end

  test "handles nil values for strings appropriately" do
    json = {
      qualitative_feedback: nil,
      feedback_items: [],
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/qualitative_feedback/, error.message)
  end

  test "validates feedback_items is an array" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: "not an array",
      criterion_levels: [],
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/feedback_items.*array/, error.message)
  end

  test "validates criterion_levels is an array" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: "not an array",
      checks: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/criterion_levels.*array/, error.message)
  end

  test "validates checks is an array" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: "not an array"
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/checks.*array/, error.message)
  end

  test "enhanced error message for JSON parse errors" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    error = assert_raises(JSON::ParserError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
    assert_match(/Failed to parse student work feedback response as valid JSON/, error.message)
  end

  test "logs structured error data with student work context" do
    json = {
      qualitative_feedback: "Some feedback",
      feedback_items: [],
      criterion_levels: [],
      checks: [
        {
          check_type: "plagiarism",
          score: "not_a_number",
          explanation: "Score is not numeric"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # We can't easily test logging output, but we can verify the error still works
    assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: @context)
    end
  end
end
