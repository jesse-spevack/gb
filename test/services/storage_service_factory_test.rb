require "test_helper"

class StorageServiceFactoryTest < ActiveSupport::TestCase
  test "creates storage service for generate_rubric process type" do
    service = StorageServiceFactory.create("generate_rubric")

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "creates storage service for grade_student_work process type" do
    service = StorageServiceFactory.create("grade_student_work")

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "creates storage service for generate_summary_feedback process type" do
    service = StorageServiceFactory.create("generate_summary_feedback")

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "creates default storage service for unknown process type" do
    service = StorageServiceFactory.create("unknown_type")

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "handles nil process type gracefully" do
    service = StorageServiceFactory.create(nil)

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "raises error for unsupported types when strict mode enabled" do
    assert_raises(StorageServiceFactory::UnsupportedProcessTypeError) do
      StorageServiceFactory.create("unsupported_type", strict: true)
    end
  end

  test "created storage service can store data" do
    service = StorageServiceFactory.create("generate_rubric")
    assignment = assignments(:english_essay)
    parsed_data = { test: "data" }

    result = service.store(assignment, parsed_data)

    # Should return some kind of result
    assert_not_nil result
  end

  test "supports configuration options" do
    config = { validation: true, async: false }
    service = StorageServiceFactory.create("generate_rubric", config: config)

    assert_not_nil service
    assert_respond_to service, :store
  end

  test "supported_types returns all known process types" do
    supported = StorageServiceFactory.supported_types

    assert_includes supported, "generate_rubric"
    assert_includes supported, "grade_student_work"
    assert_includes supported, "generate_summary_feedback"
    assert_equal 3, supported.size
  end

  test "supports? returns true for known process types" do
    assert StorageServiceFactory.supports?("generate_rubric")
    assert StorageServiceFactory.supports?("grade_student_work")
    assert StorageServiceFactory.supports?("generate_summary_feedback")
  end

  test "supports? returns false for unknown process types" do
    refute StorageServiceFactory.supports?("unknown_type")
    refute StorageServiceFactory.supports?(nil)
    refute StorageServiceFactory.supports?("")
  end

  test "created storage services return structured result with expected fields" do
    service = StorageServiceFactory.create("generate_rubric")
    assignment = assignments(:english_essay)
    parsed_data = { rubric: "test rubric data" }

    result = service.store(assignment, parsed_data)

    assert result.key?(:stored)
    assert result.key?(:storage_type)
    assert result.key?(:stored_at)
    assert_equal "rubric_storage", result[:storage_type]
  end

  test "default storage service returns basic result data" do
    service = StorageServiceFactory.create("unknown_type")
    assignment = assignments(:english_essay)
    parsed_data = { some: "data" }

    result = service.store(assignment, parsed_data)

    assert result.key?(:stored)
    assert result.key?(:storage_type)
    assert result.key?(:stored_at)
    assert_equal "default", result[:storage_type]
  end

  test "factory maintains consistency across multiple calls" do
    service1 = StorageServiceFactory.create("generate_rubric")
    service2 = StorageServiceFactory.create("generate_rubric")

    assert_equal service1, service2
  end
end
