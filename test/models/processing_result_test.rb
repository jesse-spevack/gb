require "test_helper"

class ProcessingResultTest < ActiveSupport::TestCase
  test "initializes with success and data" do
    result = ProcessingResult.new(success: true, data: { test: "data" })

    assert result.success
    assert_equal({ test: "data" }, result.data)
    assert_nil result.error_message
  end

  test "initializes with failure and error message" do
    result = ProcessingResult.new(success: false, error_message: "Something went wrong")

    assert_not result.success
    assert_equal "Something went wrong", result.error_message
    assert_nil result.data
  end

  test "initializes with all parameters" do
    result = ProcessingResult.new(
      success: true,
      data: { result: "success" },
      error_message: "warning"
    )

    assert result.success
    assert_equal({ result: "success" }, result.data)
    assert_equal "warning", result.error_message
  end

  test "success? returns true when successful" do
    result = ProcessingResult.new(success: true)

    assert result.success?
  end

  test "success? returns false when not successful" do
    result = ProcessingResult.new(success: false)

    assert_not result.success?
  end

  test "failure? returns false when successful" do
    result = ProcessingResult.new(success: true)

    assert_not result.failure?
  end

  test "failure? returns true when not successful" do
    result = ProcessingResult.new(success: false)

    assert result.failure?
  end

  test "initializes with required success parameter only" do
    result = ProcessingResult.new(success: true)

    assert result.success
    assert_nil result.data
    assert_nil result.error_message
  end
end
