# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated assignment summaries from the pipeline
    #
    # This service is called as part of the AssignmentSummaryPipeline after
    # the LLM has analyzed all student feedback and generated class-wide insights.
    # It creates a new AssignmentSummary record with aggregated feedback patterns.
    #
    # Expected context structure:
    #   - context.assignment: The Assignment record
    #   - context.student_feedbacks: Array of processed student work (optional)
    #   - context.parsed_response: OpenStruct containing:
    #     - qualitative_insights: String (class-wide analysis)
    #     - feedback_items: Array of OpenStructs with:
    #       - item_type: String ('strength' or 'opportunity')
    #       - title: String
    #       - description: String
    #       - evidence: String
    #
    # Updates context with:
    #   - context.saved_summary: The created AssignmentSummary with feedback items
    #
    # @example
    #   context = Pipeline::Context::AssignmentSummary.new
    #   context.assignment = assignment_record
    #   context.student_feedbacks = processed_student_works
    #   context.parsed_response = parsed_llm_response
    #   result = Pipeline::Storage::AssignmentSummaryService.call(context: context)
    #
    class AssignmentSummaryService
      def self.call(context:)
        Rails.logger.info("Storing summary for assignment: #{context.assignment.id}")

        ActiveRecord::Base.transaction do
          persist_summary(context)
        end

        context
      rescue => e
        Rails.logger.error("Failed to store assignment summary: #{e.message}")
        raise
      end

      private

      def self.persist_summary(context)
        assignment = context.assignment
        parsed_response = context.parsed_response

        # Create assignment summary record
        summary = AssignmentSummary.create!(
          assignment: assignment,
          qualitative_insights: parsed_response.qualitative_insights,
          student_work_count: context.student_work_count
        )

        # Create feedback items (class-wide strengths and opportunities)
        create_feedback_items(summary, parsed_response.feedback_items)

        # Update context with saved summary
        context.saved_summary = summary
      end

      def self.create_feedback_items(summary, feedback_items_data)
        feedback_items_data.each do |item_data|
          FeedbackItem.create!(
            feedbackable: summary,
            item_type: item_data.item_type,
            title: item_data.title,
            description: item_data.description,
            evidence: item_data.evidence
          )
        end
      end
    end
  end
end
