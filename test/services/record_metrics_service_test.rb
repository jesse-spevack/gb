# frozen_string_literal: true

require "test_helper"

# Use the same mock context classes defined in broadcast_service_test.rb
unless defined?(Pipeline::Context::Base)
  module Pipeline
    module Context
      class Base
        attr_accessor :assignment, :status, :metrics, :errors, :parsed_response, :started_at, :total_duration_ms

        def initialize
          @metrics = {}
          @errors = []
          @started_at = Time.current
        end

        def add_metric(key, value)
          @metrics ||= {}
          @metrics[key] = value
        end
      end

      class Rubric < Base
        attr_accessor :rubric
      end

      class StudentWork < Base
        attr_accessor :student_work
      end

      class AssignmentSummary < Base
        attr_accessor :assignment_summary
      end
    end
  end
end

class RecordMetricsServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers
  def setup
    # Cache fixture lookup to reduce database queries
    @assignment = assignments(:english_essay)
    @rubric = rubrics(:english_essay_rubric)
    @student_work = student_works(:student_essay_one)
    @summary = assignment_summaries(:literary_analysis_summary)

    # Pre-build a context object for reuse
    @base_context = Pipeline::Context::Rubric.new
    @base_context.rubric = @rubric
  end

  test "records metrics for completed pipeline" do
    # Use fixed reference time to avoid test flakiness
    reference_time = Time.zone.local(2025, 1, 1, 12, 0, 0)
    travel_to reference_time

    # Use the pre-built context object
    context = @base_context.dup
    context.add_metric(:llm_request_ms, 3500)
    context.add_metric(:tokens_used, 1200)

    # Set started_at exactly 5 seconds in the past
    context.instance_variable_set(:@started_at, reference_time - 5)

    assert_difference "ProcessingMetric.count", 1 do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal @rubric, metric.processable
    assert_equal :pending, metric.status.to_sym
    assert_equal @assignment, metric.assignment
    assert_equal @assignment.user, metric.user
    assert_equal 5000, metric.total_duration_ms
    assert_equal 3500, metric.llm_duration_ms

    travel_back
  end

  test "records metrics for different processable types" do
    # Test with StudentWork
    student_work = @student_work
    context = Pipeline::Context::StudentWork.new
    context.student_work = student_work
    context.instance_variable_set(:@parsed_response, { feedback: "Great!" })
    context.add_metric(:llm_request_ms, 2000)

    assert_difference "ProcessingMetric.count", 1 do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal student_work, metric.processable
    assert_equal :completed, metric.status.to_sym
    assert_equal student_work.assignment, metric.assignment
  end

  test "determines failed status from context errors" do
    context = @base_context.dup
    errors = [ "LLM request failed" ]
    context.instance_variable_set(:@errors, errors)
    def context.errors
      @errors
    end

    # Use travel_to for time freezing
    travel_to Time.zone.local(2025, 1, 1, 12, 0, 0) do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal :failed, metric.status.to_sym
  end

  test "returns context unchanged" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    original_metrics = { test: "value" }
    context.instance_variable_set(:@metrics, original_metrics)

    result = RecordMetricsService.call(context: context)

    assert_equal context, result
    assert_equal original_metrics, result.metrics
  end

  test "stores pipeline type in metrics data" do
    # Use pre-built context
    context = @base_context.dup

    # Use travel_to for consistent time testing
    travel_to Time.zone.local(2025, 1, 1, 12, 0, 0) do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal "rubric_generation", metric.metrics_data["pipeline_type"]
  end

  test "handles assignment summary metrics" do
    summary = @summary
    context = Pipeline::Context::AssignmentSummary.new
    context.instance_variable_set(:@assignment_summary, summary)
    # Define custom methods to ensure the test works properly
    def context.processable
      @assignment_summary
    end
    def context.assignment
      @assignment_summary&.assignment
    end
    context.add_metric(:llm_request_ms, 4000)

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal summary, metric.processable
    assert_equal summary.assignment, metric.assignment
    assert_equal "summary_generation", metric.metrics_data["pipeline_type"]
  end

  test "records zero duration for instant operations" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal 0, metric.llm_duration_ms
  end

  test "calculates total duration from started_at" do
    # Use fixed reference time to avoid test flakiness
    reference_time = Time.zone.local(2025, 1, 1, 12, 0, 0)
    travel_to reference_time

    context = @base_context.dup
    # Set the start time 2.5 seconds in the past
    context.instance_variable_set(:@started_at, reference_time - 2.5)

    # Jump forward exactly 2.5 seconds for perfect timing
    travel_to reference_time do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal 2500, metric.total_duration_ms

    # Clean up time helpers
    travel_back
  end
end
