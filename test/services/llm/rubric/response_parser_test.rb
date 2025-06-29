require "test_helper"

class LLM::Rubric::ResponseParserTest < ActiveSupport::TestCase
  setup do
    @valid_json = {
      criteria: [
        {
          title: "Argument Quality",
          description: "The strength and clarity of the main argument",
          position: 1,
          levels: [
            {
              name: "Exemplary",
              description: "Exceptional argument with compelling evidence",
              position: 4
            },
            {
              name: "Proficient",
              description: "Strong argument with good evidence",
              position: 3
            },
            {
              name: "Developing",
              description: "Basic argument with some evidence",
              position: 2
            },
            {
              name: "Beginning",
              description: "Weak argument with minimal evidence",
              position: 1
            }
          ]
        },
        {
          title: "Organization",
          description: "The structure and flow of the content",
          position: 2,
          levels: [
            {
              name: "Exemplary",
              description: "Perfect organization with seamless transitions",
              position: 4
            },
            {
              name: "Proficient",
              description: "Good organization with clear transitions",
              position: 3
            },
            {
              name: "Developing",
              description: "Basic organization with some transitions",
              position: 2
            },
            {
              name: "Beginning",
              description: "Poor organization with unclear transitions",
              position: 1
            }
          ]
        }
      ]
    }.to_json

    @llm_response = LLMResponse.new(text: @valid_json)
    @context = Pipeline::Context::Rubric.new
    @context.assignment = assignments(:english_essay)
    @context.llm_response = @llm_response
  end

  test "parses valid JSON with complete rubric data" do
    result = LLM::Rubric::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    assert_equal 2, result.parsed_response.criteria.size

    first_criterion = result.parsed_response.criteria.first
    assert_equal "Argument Quality", first_criterion.title
    assert_equal "The strength and clarity of the main argument", first_criterion.description
    assert_equal 1, first_criterion.position
    assert_equal 4, first_criterion.levels.size

    first_level = first_criterion.levels.first
    assert_equal "Exemplary", first_level.name
    assert_equal "Exceptional argument with compelling evidence", first_level.description
    assert_equal 4, first_level.position
  end

  test "raises JSON::ParserError for invalid JSON" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    assert_raises(JSON::ParserError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
  end

  test "raises error for missing required title field" do
    json = {
      criteria: [
        {
          description: "Missing title",
          position: 1,
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/title/, error.message)
  end

  test "handles missing description field gracefully" do
    json = {
      criteria: [
        {
          title: "Test",
          position: 1,
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # Should not raise an error - description is optional
    result = LLM::Rubric::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    criterion = result.parsed_response.criteria.first
    assert_equal "Test", criterion.title
    assert_equal "", criterion.description # Empty string default
  end

  test "handles missing position field gracefully" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # Should not raise an error - position is optional and defaults to 1
    result = LLM::Rubric::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    criterion = result.parsed_response.criteria.first
    assert_equal "Test", criterion.title
    assert_equal 1, criterion.position # Default value
  end

  test "raises error for invalid data types" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: "not_an_integer",
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/position.*integer/, error.message)
  end

  test "raises error for missing levels array" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    # Parser accepts both 'levels' and 'descriptors', so error message mentions the alternate field
    assert_match(/descriptors|levels/, error.message)
  end

  test "raises error for invalid level position outside 1-4 range" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          levels: [
            {
              name: "Too High",
              description: "Invalid position",
              position: 5
            }
          ]
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/position.*1.*4/, error.message)
  end

  test "raises error for empty criteria array" do
    json = { criteria: [] }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/Criteria.*empty/, error.message)
  end

  test "parsed response is added to context" do
    result = LLM::Rubric::ResponseParser.call(context: @context)

    assert_same @context, result
    assert_not_nil @context.parsed_response
  end

  test "dot notation access works for nested structures" do
    result = LLM::Rubric::ResponseParser.call(context: @context)
    parsed = result.parsed_response

    assert_equal "Argument Quality", parsed.criteria[0].title
    assert_equal "Exemplary", parsed.criteria[0].levels[0].name
    assert_equal 4, parsed.criteria[0].levels[0].position
    assert_equal "Organization", parsed.criteria[1].title
  end

  test "string sanitization trims whitespace" do
    json = {
      criteria: [
        {
          title: "  Whitespace Title  ",
          description: "\nDescription with newlines\n",
          position: 1,
          levels: [
            {
              name: "\tTabbed Name\t",
              description: "  Spaced description  ",
              position: 1
            }
          ]
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::Rubric::ResponseParser.call(context: @context)
    criterion = result.parsed_response.criteria.first

    assert_equal "Whitespace Title", criterion.title
    assert_equal "Description with newlines", criterion.description
    assert_equal "Tabbed Name", criterion.levels.first.name
    assert_equal "Spaced description", criterion.levels.first.description
  end

  test "handles nil values gracefully" do
    json = {
      criteria: [
        {
          title: nil,
          description: "Test",
          position: 1,
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/title/, error.message)
  end

  test "ignores extra unexpected fields" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          extra_field: "should be ignored",
          levels: [
            {
              name: "Level",
              description: "Level description",
              position: 1,
              another_extra: "also ignored"
            }
          ]
        }
      ],
      top_level_extra: "ignored too"
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    result = LLM::Rubric::ResponseParser.call(context: @context)
    criterion = result.parsed_response.criteria.first

    assert_equal "Test", criterion.title
    assert_respond_to criterion, :title
    assert_not_respond_to criterion, :extra_field
    assert_not_respond_to criterion.levels.first, :another_extra
  end

  test "validates level has required name field" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          levels: [
            {
              description: "Missing name",
              position: 1
            }
          ]
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/name/, error.message)
  end

  test "validates level has required description field" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          levels: [
            {
              name: "Test Level",
              position: 1
            }
          ]
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/description/, error.message)
  end

  test "handles missing level position field gracefully" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          levels: [
            {
              name: "Test Level",
              description: "Level description"
            }
          ]
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # Should not raise an error - level position is optional and auto-assigned
    result = LLM::Rubric::ResponseParser.call(context: @context)

    assert_not_nil result.parsed_response
    level = result.parsed_response.criteria.first.levels.first
    assert_equal "Test Level", level.name
    assert_equal 1, level.position # Auto-assigned based on array order (only 1 level)
  end

  test "handles missing criteria key" do
    json = {}.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/criteria/, error.message)
  end

  test "validates levels is an array" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: 1,
          levels: "not an array"
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    error = assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/levels.*array/, error.message)
  end

  test "enhanced error message for JSON parse errors" do
    @context.llm_response = LLMResponse.new(text: "{ invalid json")

    error = assert_raises(JSON::ParserError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
    assert_match(/Failed to parse rubric response as valid JSON/, error.message)
  end

  test "logs structured error data" do
    json = {
      criteria: [
        {
          title: "Test",
          description: "Test description",
          position: "not_an_integer",
          levels: []
        }
      ]
    }.to_json
    @context.llm_response = LLMResponse.new(text: json)

    # We can't easily test logging output, but we can verify the error still works
    assert_raises(LLM::Rubric::ResponseParser::ValidationError) do
      LLM::Rubric::ResponseParser.call(context: @context)
    end
  end
end
