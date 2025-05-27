# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated assignment summaries from the pipeline
    class AssignmentSummaryService
      def self.call(context:)
        Rails.logger.info("Storing summary for assignment: #{context.assignment.id}")
        context.saved_summary = persist_to_database(context)
        context
      end

      def self.persist_to_database(context)
        # This would contain actual persistence logic in a real implementation
        assignment = context.assignment

        if context.parsed_response.present?
          summary = assignment.assignment_summary || AssignmentSummary.new(assignment: assignment)
          summary.update!(
            qualitative_insights: context.parsed_response[:qualitative_insights],
            student_work_count: assignment.student_works.count
          )

          summary
        else
          assignment.assignment_summary
        end
      end
    end
  end
end
