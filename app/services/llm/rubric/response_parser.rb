# frozen_string_literal: true

module LLM
  module Rubric
    # Parser for LLM-generated rubric responses
    class ResponseParser
      def self.call(context:)
        Rails.logger.info("Parsing rubric response for assignment: #{context.assignment.id}")
        # This would contain actual parsing logic in a real implementation
        context
      end
    end
  end
end
