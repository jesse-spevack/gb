require "test_helper"

module Pipeline
  class ProcessingResultTest < ActiveSupport::TestCase
    test "initializes with success status" do
      result = ProcessingResult.new(success: true)

      assert result.success
      assert result.successful?
      assert_not result.failed?
      assert_nil result.data
      assert_empty result.errors
      assert_empty result.metrics
    end

    test "initializes with failure status" do
      result = ProcessingResult.new(success: false, errors: [ "Something went wrong" ])

      assert_not result.success
      assert_not result.successful?
      assert result.failed?
      assert_nil result.data
      assert_equal [ "Something went wrong" ], result.errors
    end

    test "initializes with data payload" do
      data = { key: "value" }
      result = ProcessingResult.new(success: true, data: data)

      assert_equal data, result.data
    end

    test "freezes metrics to ensure immutability" do
      metrics = { "total_duration_ms" => 100 }
      result = ProcessingResult.new(success: true, metrics: metrics)

      assert result.metrics.frozen?
      assert_raises(FrozenError) do
        result.metrics["new_key"] = "value"
      end
    end

    test "provides timing_ms helper" do
      result = ProcessingResult.new(success: true, metrics: { "total_duration_ms" => 150 })

      assert_equal 150, result.timing_ms
    end

    test "provides llm_timing_ms helper" do
      result = ProcessingResult.new(success: true, metrics: { "llm_request_ms" => 75 })

      assert_equal 75, result.llm_timing_ms
    end

    test "returns zero for missing timing metrics" do
      result = ProcessingResult.new(success: true)

      assert_equal 0, result.timing_ms
      assert_equal 0, result.llm_timing_ms
    end
  end
end
