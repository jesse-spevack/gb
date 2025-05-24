require "test_helper"

class ResponseParserFactoryTest < ActiveSupport::TestCase
  test "creates parser for generate_rubric process type" do
    parser = ResponseParserFactory.create("generate_rubric")

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "creates parser for grade_student_work process type" do
    parser = ResponseParserFactory.create("grade_student_work")

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "creates parser for generate_summary_feedback process type" do
    parser = ResponseParserFactory.create("generate_summary_feedback")

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "creates default parser for unknown process type" do
    parser = ResponseParserFactory.create("unknown_type")

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "handles nil process type gracefully" do
    parser = ResponseParserFactory.create(nil)

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "raises error for unsupported types when strict mode enabled" do
    assert_raises(ResponseParserFactory::UnsupportedProcessTypeError) do
      ResponseParserFactory.create("unsupported_type", strict: true)
    end
  end

  test "created parser can parse response text" do
    parser = ResponseParserFactory.create("generate_rubric")
    result = parser.parse("test response")

    # Should return some kind of structured data
    assert_not_nil result
  end

  test "supports configuration options" do
    config = { format: "json", validation: true }
    parser = ResponseParserFactory.create("generate_rubric", config: config)

    assert_not_nil parser
    assert_respond_to parser, :parse
  end

  test "supported_types returns all known process types" do
    supported = ResponseParserFactory.supported_types

    assert_includes supported, "generate_rubric"
    assert_includes supported, "grade_student_work"
    assert_includes supported, "generate_summary_feedback"
    assert_equal 3, supported.size
  end

  test "supports? returns true for known process types" do
    assert ResponseParserFactory.supports?("generate_rubric")
    assert ResponseParserFactory.supports?("grade_student_work")
    assert ResponseParserFactory.supports?("generate_summary_feedback")
  end

  test "supports? returns false for unknown process types" do
    refute ResponseParserFactory.supports?("unknown_type")
    refute ResponseParserFactory.supports?(nil)
    refute ResponseParserFactory.supports?("")
  end

  test "created parsers return structured data with expected fields" do
    parser = ResponseParserFactory.create("generate_rubric")
    result = parser.parse("sample rubric response")

    assert_equal "sample rubric response", result[:raw_response]
    assert_equal "rubric_generation", result[:parser_type]
    assert_instance_of ActiveSupport::TimeWithZone, result[:parsed_at]
    assert result.key?(:rubric_data)
  end

  test "default parser returns basic structured data" do
    parser = ResponseParserFactory.create("unknown_type")
    result = parser.parse("some response")

    assert_equal "some response", result[:raw_response]
    assert_equal "default", result[:parser_type]
    assert_instance_of ActiveSupport::TimeWithZone, result[:parsed_at]
  end

  test "factory maintains consistency across multiple calls" do
    parser1 = ResponseParserFactory.create("generate_rubric")
    parser2 = ResponseParserFactory.create("generate_rubric")

    assert_equal parser1, parser2
  end
end
