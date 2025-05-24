require "test_helper"

class StorageServiceFactoryIntegrationTest < ActiveSupport::TestCase
  # Mock classes for testing integration
  class MockPromptTemplate
    def self.build(template_type, variables)
      "Mock prompt for #{template_type}"
    end
  end

  class MockResponseParser
    def self.parse(response_text)
      { parsed_data: "Mock parsed result from #{response_text}" }
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

  test "StorageServiceFactory works with ProcessingTask configuration for rubric generation" do
    storage_service = StorageServiceFactory.create("generate_rubric")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: MockResponseParser,
      storage_service: storage_service,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      user: @user,
      configuration: configuration
    )

    # Verify task uses the factory-created storage service
    assert_equal storage_service, task.storage_service
    assert_respond_to task.storage_service, :store

    # Test that the storage service can store data
    parsed_result = { rubric: "test rubric data" }
    result = task.storage_service.store(@assignment, parsed_result)

    assert result[:stored]
    assert_equal "rubric_storage", result[:storage_type]
    assert result.key?(:stored_at)
  end

  test "StorageServiceFactory works with ProcessingTask configuration for student work grading" do
    storage_service = StorageServiceFactory.create("grade_student_work")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: MockResponseParser,
      storage_service: storage_service,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "grade_student_work",
      user: @user,
      configuration: configuration
    )

    # Verify task uses the factory-created storage service
    assert_equal storage_service, task.storage_service

    # Test that the storage service can store data
    parsed_result = { feedback: "test feedback data" }
    result = task.storage_service.store(@assignment, parsed_result)

    assert result[:stored]
    assert_equal "student_work_storage", result[:storage_type]
    assert result.key?(:stored_at)
  end

  test "StorageServiceFactory works with ProcessingTask configuration for summary feedback" do
    storage_service = StorageServiceFactory.create("generate_summary_feedback")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: MockResponseParser,
      storage_service: storage_service,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_summary_feedback",
      user: @user,
      configuration: configuration
    )

    # Verify task uses the factory-created storage service
    assert_equal storage_service, task.storage_service

    # Test that the storage service can store data
    parsed_result = { summary: "test summary data" }
    result = task.storage_service.store(@assignment, parsed_result)

    assert result[:stored]
    assert_equal "summary_feedback_storage", result[:storage_type]
    assert result.key?(:stored_at)
  end

  test "StorageServiceFactory provides default storage service for unknown process types" do
    storage_service = StorageServiceFactory.create("unknown_process_type")

    configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: MockResponseParser,
      storage_service: storage_service,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    # Create task with a known process type but using default storage service
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric", # Known type but using default storage service
      user: @user,
      configuration: configuration
    )

    # Test that the storage service can store data
    parsed_result = { some: "data" }
    result = task.storage_service.store(@assignment, parsed_result)

    assert result[:stored]
    assert_equal "default", result[:storage_type]
    assert result.key?(:stored_at)
  end

  test "all storage services store processable information correctly" do
    process_types = [ "generate_rubric", "grade_student_work", "generate_summary_feedback" ]

    process_types.each do |process_type|
      storage_service = StorageServiceFactory.create(process_type)
      parsed_result = { test: "data for #{process_type}" }

      result = storage_service.store(@assignment, parsed_result)

      assert result[:stored], "#{process_type} storage service should mark data as stored"
      assert_equal @assignment.id, result[:processable_id], "#{process_type} should store processable ID"
      assert_equal @assignment.class.name, result[:processable_type], "#{process_type} should store processable type"
      assert result.key?(:stored_at), "#{process_type} should include stored_at timestamp"
    end
  end
end
