require "test_helper"

class ProcessingTaskConfigurationTest < ActiveSupport::TestCase
  test "initializes with all required components" do
    config = ProcessingTaskConfiguration.new(
      prompt_template: "MockPromptTemplate",
      response_parser: "MockResponseParser",
      storage_service: "MockStorageService",
      broadcaster: "MockBroadcaster",
      status_manager: "MockStatusManager"
    )

    assert_equal "MockPromptTemplate", config.prompt_template
    assert_equal "MockResponseParser", config.response_parser
    assert_equal "MockStorageService", config.storage_service
    assert_equal "MockBroadcaster", config.broadcaster
    assert_equal "MockStatusManager", config.status_manager
  end

  test "raises error when prompt_template is missing" do
    assert_raises(ArgumentError, "Prompt template is required") do
      ProcessingTaskConfiguration.new(
        response_parser: "MockResponseParser",
        storage_service: "MockStorageService",
        broadcaster: "MockBroadcaster",
        status_manager: "MockStatusManager"
      )
    end
  end

  test "raises error when response_parser is missing" do
    assert_raises(ArgumentError, "Response parser is required") do
      ProcessingTaskConfiguration.new(
        prompt_template: "MockPromptTemplate",
        storage_service: "MockStorageService",
        broadcaster: "MockBroadcaster",
        status_manager: "MockStatusManager"
      )
    end
  end

  test "raises error when storage_service is missing" do
    assert_raises(ArgumentError, "Storage service is required") do
      ProcessingTaskConfiguration.new(
        prompt_template: "MockPromptTemplate",
        response_parser: "MockResponseParser",
        broadcaster: "MockBroadcaster",
        status_manager: "MockStatusManager"
      )
    end
  end

  test "raises error when broadcaster is missing" do
    assert_raises(ArgumentError, "Broadcaster is required") do
      ProcessingTaskConfiguration.new(
        prompt_template: "MockPromptTemplate",
        response_parser: "MockResponseParser",
        storage_service: "MockStorageService",
        status_manager: "MockStatusManager"
      )
    end
  end

  test "raises error when status_manager is missing" do
    assert_raises(ArgumentError, "Status manager is required") do
      ProcessingTaskConfiguration.new(
        prompt_template: "MockPromptTemplate",
        response_parser: "MockResponseParser",
        storage_service: "MockStorageService",
        broadcaster: "MockBroadcaster"
      )
    end
  end

  test "raises error when initialized with nil values" do
    assert_raises(ArgumentError) do
      ProcessingTaskConfiguration.new(
        prompt_template: nil,
        response_parser: "MockResponseParser",
        storage_service: "MockStorageService",
        broadcaster: "MockBroadcaster",
        status_manager: "MockStatusManager"
      )
    end
  end

  test "allows any type of object as component values" do
    # Components can be classes, strings, or any other objects
    config = ProcessingTaskConfiguration.new(
      prompt_template: String,
      response_parser: Object.new,
      storage_service: :storage_service_symbol,
      broadcaster: 123,
      status_manager: [ "array", "value" ]
    )

    assert_equal String, config.prompt_template
    assert_kind_of Object, config.response_parser
    assert_equal :storage_service_symbol, config.storage_service
    assert_equal 123, config.broadcaster
    assert_equal [ "array", "value" ], config.status_manager
  end
end
