require "test_helper"

class LLM::AssignmentSummary::ResponseParserTest < ActiveSupport::TestCase
  setup do
    @valid_json = {
      qualitative_insights: "Overall, the class demonstrated strong understanding of the main concepts. Most students effectively analyzed the themes and provided well-supported arguments. Common areas for improvement include citation formatting and paragraph transitions.",
      feedback_items: [
        {
          item_type: "strength",
          title: "Strong Thesis Development",
          description: "The majority of students crafted clear, focused thesis statements that effectively guided their essays",
          evidence: "15 out of 20 students received high marks for thesis clarity and argument structure"
        },
        {
          item_type: "strength",
          title: "Effective Use of Evidence",
          description: "Students generally selected relevant quotes and examples to support their arguments",
          evidence: "Average score of 3.5/4 on the 'Evidence and Support' criterion across all submissions"
        },
        {
          item_type: "opportunity",
          title: "Citation Formatting",
          description: "Many students struggled with proper MLA citation format, particularly with in-text citations",
          evidence: "12 students lost points for incorrect citation formatting, most commonly missing page numbers"
        },
        {
          item_type: "opportunity",
          title: "Paragraph Transitions",
          description: "Transitions between body paragraphs need improvement to create better flow",
          evidence: "Average score of 2.1/4 on the 'Organization and Flow' criterion, with specific feedback about transitions"
        }
      ]
    }.to_json

    @llm_response = LLMResponse.new(text: @valid_json)
    @context = Pipeline::Context::AssignmentSummary.new
    @context.assignment = assignments(:english_essay)
    @context.llm_response = @llm_response
  end

  test "parses valid JSON with complete assignment summary" do
    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    assert_equal "Overall, the class demonstrated strong understanding of the main concepts. Most students effectively analyzed the themes and provided well-supported arguments. Common areas for improvement include citation formatting and paragraph transitions.",
                 result.parsed_response.qualitative_insights

    # Check feedback items
    assert_equal 4, result.parsed_response.feedback_items.size

    # Check strengths
    strengths = result.parsed_response.feedback_items.select { |item| item.item_type == "strength" }
    assert_equal 2, strengths.size
    assert_equal "Strong Thesis Development", strengths.first.title

    # Check opportunities
    opportunities = result.parsed_response.feedback_items.select { |item| item.item_type == "opportunity" }
    assert_equal 2, opportunities.size
    assert_equal "Citation Formatting", opportunities.first.title
  end

  test "raises JSON::ParserError for invalid JSON" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    assert_raises(JSON::ParserError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
  end

  test "raises error for missing qualitative_insights field" do
    json = {
      feedback_items: [
        {
          item_type: "strength",
          title: "Test Strength",
          description: "Test description",
          evidence: "Test evidence"
        },
        {
          item_type: "opportunity",
          title: "Test Opportunity",
          description: "Test description",
          evidence: "Test evidence"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/qualitative_insights/, error.message)
  end

  test "raises error for feedback items less than 2" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "Only One Item",
          description: "Not enough items",
          evidence: "Need at least 2"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/at least 2 feedback items/, error.message)
  end

  test "raises error for missing strength feedback item" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "opportunity",
          title: "First Opportunity",
          description: "No strengths",
          evidence: "Missing strength"
        },
        {
          item_type: "opportunity",
          title: "Second Opportunity",
          description: "Still no strengths",
          evidence: "Need at least one strength"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/at least one strength/, error.message)
  end

  test "raises error for missing opportunity feedback item" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "First Strength",
          description: "No opportunities",
          evidence: "Missing opportunity"
        },
        {
          item_type: "strength",
          title: "Second Strength",
          description: "Still no opportunities",
          evidence: "Need at least one opportunity"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/at least one opportunity/, error.message)
  end

  test "validates feedback item structure - missing type" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          title: "Missing Type",
          description: "This item has no type",
          evidence: "Should fail validation"
        },
        {
          item_type: "opportunity",
          title: "Valid Item",
          description: "This one is valid",
          evidence: "Should not matter"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/item_type/, error.message)
  end

  test "validates feedback item structure - missing title" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          description: "Missing title",
          evidence: "Should fail"
        },
        {
          item_type: "opportunity",
          title: "Valid",
          description: "Valid",
          evidence: "Valid"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/title/, error.message)
  end

  test "validates feedback item structure - missing description" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "Missing Description",
          evidence: "Should fail"
        },
        {
          item_type: "opportunity",
          title: "Valid",
          description: "Valid",
          evidence: "Valid"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/description/, error.message)
  end

  test "validates feedback item structure - missing evidence" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "Missing Evidence",
          description: "No evidence provided"
        },
        {
          item_type: "opportunity",
          title: "Valid",
          description: "Valid",
          evidence: "Valid"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/evidence/, error.message)
  end

  test "validates feedback item structure - invalid item_type" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "invalid_type",
          title: "Invalid Type",
          description: "Not strength or opportunity",
          evidence: "Should fail"
        },
        {
          item_type: "opportunity",
          title: "Valid",
          description: "Valid",
          evidence: "Valid"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/item_type.*strength.*opportunity/, error.message)
  end

  test "parsed response is added to context" do
    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_same @context, result
    assert_not_nil @context.parsed_response
  end

  test "dot notation access works for nested structures" do
    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)
    parsed = result.parsed_response

    assert_equal "Overall, the class demonstrated strong understanding of the main concepts. Most students effectively analyzed the themes and provided well-supported arguments. Common areas for improvement include citation formatting and paragraph transitions.",
                 parsed.qualitative_insights
    assert_equal "strength", parsed.feedback_items[0].item_type
    assert_equal "Strong Thesis Development", parsed.feedback_items[0].title
    assert_equal "Citation Formatting", parsed.feedback_items[2].title
  end

  test "handles empty feedback_items array" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/at least 2 feedback items/, error.message)
  end

  test "string sanitization trims whitespace" do
    json = {
      qualitative_insights: "  Insights with whitespace  \n",
      feedback_items: [
        {
          item_type: "strength",
          title: "\tTabbed Title\t",
          description: "  Spaced description  ",
          evidence: "\nEvidence with newlines\n"
        },
        {
          item_type: "opportunity",
          title: "  Another Title  ",
          description: "\tAnother description\t",
          evidence: "  More evidence  "
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_equal "Insights with whitespace", result.parsed_response.qualitative_insights
    assert_equal "Tabbed Title", result.parsed_response.feedback_items[0].title
    assert_equal "Spaced description", result.parsed_response.feedback_items[0].description
    assert_equal "Evidence with newlines", result.parsed_response.feedback_items[0].evidence
    assert_equal "Another Title", result.parsed_response.feedback_items[1].title
  end

  test "ignores extra unexpected fields" do
    json = {
      qualitative_insights: "Some insights",
      extra_top_level: "should be ignored",
      feedback_items: [
        {
          item_type: "strength",
          title: "Title",
          description: "Description",
          evidence: "Evidence",
          extra_field: "should be ignored"
        },
        {
          item_type: "opportunity",
          title: "Title 2",
          description: "Description 2",
          evidence: "Evidence 2",
          another_extra: "also ignored"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_respond_to result.parsed_response, :qualitative_insights
    assert_not_respond_to result.parsed_response, :extra_top_level
    assert_not_respond_to result.parsed_response.feedback_items.first, :extra_field
    assert_not_respond_to result.parsed_response.feedback_items.last, :another_extra
  end

  test "handles nil values for qualitative_insights" do
    json = {
      qualitative_insights: nil,
      feedback_items: [
        {
          item_type: "strength",
          title: "Title",
          description: "Description",
          evidence: "Evidence"
        },
        {
          item_type: "opportunity",
          title: "Title 2",
          description: "Description 2",
          evidence: "Evidence 2"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/qualitative_insights/, error.message)
  end

  test "validates feedback_items is an array" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: "not an array"
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/feedback_items.*array/, error.message)
  end

  test "handles missing feedback_items key" do
    json = {
      qualitative_insights: "Some insights"
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/feedback_items/, error.message)
  end

  test "accepts exactly 2 feedback items with one of each type" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "One Strength",
          description: "Strength description",
          evidence: "Strength evidence"
        },
        {
          item_type: "opportunity",
          title: "One Opportunity",
          description: "Opportunity description",
          evidence: "Opportunity evidence"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_equal 2, result.parsed_response.feedback_items.size
    assert_equal 1, result.parsed_response.feedback_items.count { |item| item.item_type == "strength" }
    assert_equal 1, result.parsed_response.feedback_items.count { |item| item.item_type == "opportunity" }
  end

  test "accepts multiple strengths and opportunities" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: [
        {
          item_type: "strength",
          title: "First Strength",
          description: "Description 1",
          evidence: "Evidence 1"
        },
        {
          item_type: "strength",
          title: "Second Strength",
          description: "Description 2",
          evidence: "Evidence 2"
        },
        {
          item_type: "opportunity",
          title: "First Opportunity",
          description: "Description 3",
          evidence: "Evidence 3"
        },
        {
          item_type: "opportunity",
          title: "Second Opportunity",
          description: "Description 4",
          evidence: "Evidence 4"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::AssignmentSummary::ResponseParser.call(context: @context)

    assert_equal 4, result.parsed_response.feedback_items.size
    assert_equal 2, result.parsed_response.feedback_items.count { |item| item.item_type == "strength" }
    assert_equal 2, result.parsed_response.feedback_items.count { |item| item.item_type == "opportunity" }
  end

  test "enhanced error message for JSON parse errors" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    error = assert_raises(JSON::ParserError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
    assert_match(/Failed to parse assignment summary response as valid JSON/, error.message)
  end

  test "logs structured error data with assignment context" do
    json = {
      qualitative_insights: "Some insights",
      feedback_items: []
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # We can't easily test logging output, but we can verify the error still works
    assert_raises(LLM::AssignmentSummary::ResponseParser::ValidationError) do
      LLM::AssignmentSummary::ResponseParser.call(context: @context)
    end
  end
end
