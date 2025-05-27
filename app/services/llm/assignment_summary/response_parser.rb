# frozen_string_literal: true

module LLM
  module AssignmentSummary
    # Parser for LLM-generated assignment summary responses
    class ResponseParser
      def self.call(context:)
        Rails.logger.info("Parsing summary response for assignment: #{context.assignment.id}")
        # This would contain actual parsing logic in a real implementation
        context
      end
    end
  end
end
