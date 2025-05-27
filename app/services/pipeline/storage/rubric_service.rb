# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated rubrics from the pipeline
    class RubricService
      def self.call(context:)
        Rails.logger.info("Storing rubric for assignment: #{context.assignment.id}")

        # This would contain actual persistence logic in a real implementation
        # Following PORO principles - keep it simple and focused
        context.rubric = create_rubric(context)
        context
      end

      private

      def self.create_rubric(context)
        # Simple implementation that would be expanded in a real implementation
        # Just returning a mock rubric object for now
        Rubric.new(assignment: context.assignment)
      end
    end
  end
end
