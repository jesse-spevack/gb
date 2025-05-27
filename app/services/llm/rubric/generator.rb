# frozen_string_literal: true

module LLM
  module Rubric
    # Generator for creating rubrics via LLM
    class Generator
      def self.call(context:)
        Rails.logger.info("Generating rubric for assignment: #{context.assignment.id}")
        # This would contain actual LLM interaction in a real implementation
        context
      end
    end
  end
end
