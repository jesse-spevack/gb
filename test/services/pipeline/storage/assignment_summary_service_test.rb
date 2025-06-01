# frozen_string_literal: true

require "ostruct"
require "test_helper"

module Pipeline
  module Storage
    class AssignmentSummaryServiceTest < ActiveSupport::TestCase
      setup do
        @assignment = assignments(:history_essay)
        @context = Pipeline::Context::AssignmentSummary.new
        @context.assignment = @assignment
        @context.parsed_response = build_parsed_response
        @context.student_feedbacks = []  # Can be populated if needed
      end

      test "creates assignment summary with correct attributes" do
        assert_difference "AssignmentSummary.count", 1 do
          AssignmentSummaryService.call(context: @context)
        end

        summary = AssignmentSummary.last
        assert_equal @assignment, summary.assignment
        assert_equal "Overall, the class demonstrated strong understanding of historical analysis...",
                     summary.qualitative_insights
        assert_equal @assignment.student_works.count, summary.student_work_count
      end

      test "creates feedback items with correct attributes" do
        assert_difference "FeedbackItem.count", 4 do
          AssignmentSummaryService.call(context: @context)
        end

        summary = AssignmentSummary.last
        feedback_items = summary.feedback_items.order(:id)

        # Check strengths
        strength1 = feedback_items.find { |f| f.item_type == "strength" && f.title == "Strong thesis statements" }
        assert_not_nil strength1
        assert_equal "Most students presented clear and focused arguments", strength1.description
        assert_equal "80% of essays had well-defined thesis statements", strength1.evidence

        strength2 = feedback_items.find { |f| f.item_type == "strength" && f.title == "Good use of evidence" }
        assert_not_nil strength2
        assert_equal "Students effectively incorporated primary sources", strength2.description
        assert_equal "Average of 5 primary sources cited per essay", strength2.evidence

        # Check opportunities
        opportunity1 = feedback_items.find { |f| f.item_type == "opportunity" && f.title == "Deeper analysis needed" }
        assert_not_nil opportunity1
        assert_equal "Many students could expand their critical analysis", opportunity1.description
        assert_equal "60% of essays would benefit from more in-depth examination", opportunity1.evidence

        opportunity2 = feedback_items.find { |f| f.item_type == "opportunity" && f.title == "Citation formatting" }
        assert_not_nil opportunity2
        assert_equal "Consistent citation format needs improvement", opportunity2.description
        assert_equal "Half the class had minor citation errors", opportunity2.evidence
      end

      test "uses context student_work_count method" do
        # Simulate having processed 10 student works
        @context.student_feedbacks = Array.new(10) { OpenStruct.new }

        AssignmentSummaryService.call(context: @context)

        summary = AssignmentSummary.last
        assert_equal 10, summary.student_work_count
        assert_equal @context.student_work_count, summary.student_work_count
      end

      test "falls back to assignment student_works count when student_feedbacks not available" do
        @context.student_feedbacks = nil

        AssignmentSummaryService.call(context: @context)

        summary = AssignmentSummary.last
        assert_equal @assignment.student_works.count, summary.student_work_count
      end

      test "updates context with saved summary" do
        result_context = AssignmentSummaryService.call(context: @context)

        assert_instance_of AssignmentSummary, result_context.saved_summary
        assert_equal @assignment, result_context.saved_summary.assignment
      end

      test "wraps all operations in a transaction" do
        # Mock a failure in feedback item creation
        FeedbackItem.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(FeedbackItem.new))

        initial_summary_count = AssignmentSummary.count
        initial_feedback_count = FeedbackItem.count

        assert_raises(ActiveRecord::RecordInvalid) do
          AssignmentSummaryService.call(context: @context)
        end

        # Verify nothing was saved due to transaction rollback
        assert_equal initial_summary_count, AssignmentSummary.count
        assert_equal initial_feedback_count, FeedbackItem.count
      end

      test "handles missing parsed response gracefully" do
        @context.parsed_response = nil

        assert_raises(NoMethodError) do
          AssignmentSummaryService.call(context: @context)
        end
      end

      test "logs errors when persistence fails" do
        # Mock creation failure
        AssignmentSummary.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(AssignmentSummary.new))

        Rails.logger.expects(:error).with(regexp_matches(/Failed to store assignment summary/))

        assert_raises(ActiveRecord::RecordInvalid) do
          AssignmentSummaryService.call(context: @context)
        end
      end

      test "creates feedback items as polymorphic association" do
        AssignmentSummaryService.call(context: @context)

        summary = AssignmentSummary.last
        feedback_item = summary.feedback_items.first

        assert_equal "AssignmentSummary", feedback_item.feedbackable_type
        assert_equal summary.id, feedback_item.feedbackable_id
      end

      private

      def build_parsed_response
        OpenStruct.new(
          qualitative_insights: "Overall, the class demonstrated strong understanding of historical analysis...",
          feedback_items: [
            OpenStruct.new(
              item_type: "strength",
              title: "Strong thesis statements",
              description: "Most students presented clear and focused arguments",
              evidence: "80% of essays had well-defined thesis statements"
            ),
            OpenStruct.new(
              item_type: "strength",
              title: "Good use of evidence",
              description: "Students effectively incorporated primary sources",
              evidence: "Average of 5 primary sources cited per essay"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Deeper analysis needed",
              description: "Many students could expand their critical analysis",
              evidence: "60% of essays would benefit from more in-depth examination"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Citation formatting",
              description: "Consistent citation format needs improvement",
              evidence: "Half the class had minor citation errors"
            )
          ]
        )
      end
    end
  end
end
