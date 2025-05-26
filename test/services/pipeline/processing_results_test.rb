require "test_helper"

module Pipeline
  class ProcessingResultsTest < ActiveSupport::TestCase
    setup do
      @success_result = ProcessingResult.new(
        success: true,
        data: { id: 1 },
        metrics: { "total_duration_ms" => 100, "llm_request_ms" => 50 }
      )

      @failure_result = ProcessingResult.new(
        success: false,
        errors: [ "Error occurred" ],
        metrics: { "total_duration_ms" => 150, "llm_request_ms" => 75 }
      )
    end

    test "initializes with empty results by default" do
      results = ProcessingResults.new

      assert_empty results.results
      assert results.successful?
      assert_not results.failed?
      assert_empty results.error_messages
      assert_equal 0, results.total_timing_ms
      assert_equal 0, results.total_llm_timing_ms
    end

    test "initializes with provided results" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_equal 2, results.results.size
      assert_includes results.results, @success_result
      assert_includes results.results, @failure_result
    end

    test "freezes results to ensure immutability" do
      results = ProcessingResults.new([ @success_result ])

      assert results.results.frozen?
      assert_raises(FrozenError) do
        results.results << @failure_result
      end
    end

    test "reports successful if all results are successful" do
      results = ProcessingResults.new([ @success_result, @success_result ])

      assert results.successful?
      assert_not results.failed?
    end

    test "reports failed if any result is failed" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_not results.successful?
      assert results.failed?
    end

    test "filters failed results" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_equal [ @failure_result ], results.failed_results
    end

    test "filters successful results" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_equal [ @success_result ], results.successful_results
    end

    test "collects unique error messages" do
      another_failure = ProcessingResult.new(
        success: false,
        errors: [ "Error occurred", "Another error" ]
      )

      results = ProcessingResults.new([ @failure_result, another_failure ])

      assert_equal [ "Error occurred", "Another error" ], results.error_messages
    end

    test "calculates total timing metrics" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_equal 250, results.total_timing_ms
      assert_equal 125, results.total_llm_timing_ms
    end

    test "supports enumerable methods" do
      results = ProcessingResults.new([ @success_result, @failure_result ])

      assert_equal 2, results.count
      assert results.any?(&:failed?)
    end
  end
end
