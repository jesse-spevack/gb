# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated student work feedback from the pipeline
    class StudentWorkService
      def self.call(context:)
        Rails.logger.info("Storing feedback for student work: #{context.student_work.id}")
        context.saved_feedback = persist_to_database(context)
        context
      end

      def self.persist_to_database(context)
        # This would contain actual persistence logic in a real implementation
        student_work = context.student_work

        if context.parsed_response.present?
          student_work.update!(
            qualitative_feedback: context.parsed_response[:qualitative_feedback]
          )
        end

        student_work
      end
    end
  end
end
