# frozen_string_literal: true

module LLM
  module StudentWork
    # Generates feedback for student work via LLM
    class Generator
      def self.call(context:)
        Rails.logger.info("Generating feedback for student work: #{context.student_work.id}")
        # This would contain actual LLM interaction in a real implementation
        context
      end
    end
  end
end
