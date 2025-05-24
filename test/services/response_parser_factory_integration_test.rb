require "test_helper"

class ResponseParserFactoryIntegrationTest < ActiveSupport::TestCase
  # Mock classes for testing integration
  class MockPromptTemplate
    def self.build(template_type, variables)
      "Mock prompt for #{template_type}"
    end
  end

  class MockStorageService
    def self.store(processable, parsed_result)
      { stored: true, result: parsed_result }
    end
  end

  class MockBroadcaster
    def self.broadcast(processable, status, data = nil)
      { broadcast: status, data: data }
    end
  end

  class MockStatusManager
    def self.update_status(processable, status)
      { status_updated: status }
    end
  end

  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
  end

  test "ResponseParserFactory works with ProcessingTask configuration for rubric generation" do
    response_parser = ResponseParserFactory.create("generate_rubric")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: response_parser,
      storage_service: MockStorageService,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      user: @user,
      configuration: configuration
    )

    # Verify task uses the factory-created parser
    assert_equal response_parser, task.response_parser
    assert_respond_to task.response_parser, :parse

    # Test that the parser can process a response
    result = task.response_parser.parse("Mock rubric response")
    assert_equal "Mock rubric response", result[:raw_response]
    assert_equal "rubric_generation", result[:parser_type]
  end

  test "ResponseParserFactory works with ProcessingTask configuration for student work grading" do
    response_parser = ResponseParserFactory.create("grade_student_work")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: response_parser,
      storage_service: MockStorageService,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "grade_student_work",
      user: @user,
      configuration: configuration
    )

    # Verify task uses the factory-created parser
    assert_equal response_parser, task.response_parser

    # Test that the parser can process a response
    result = task.response_parser.parse("Mock grading response")
    assert_equal "Mock grading response", result[:raw_response]
    assert_equal "student_work_grading", result[:parser_type]
  end

  test "ResponseParserFactory provides default parser for unknown process types" do
    response_parser = ResponseParserFactory.create("unknown_process_type")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: response_parser,
      storage_service: MockStorageService,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    # Create task with a known process type but using default parser
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric", # Known type but using default parser
      user: @user,
      configuration: configuration
    )

    # Test that the parser can process a response
    result = task.response_parser.parse("Some response")
    assert_equal "Some response", result[:raw_response]
    assert_equal "default", result[:parser_type]
  end
end
