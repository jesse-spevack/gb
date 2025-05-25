# frozen_string_literal: true

module PromptInput
  class Rubric
    def self.from(assignment:)
      new(assignment: assignment)
    end

    def initialize(assignment:)
      @assignment = assignment
      @rubric = assignment.rubric

      raise "Rubric not found for assignment #{assignment.id}" unless @rubric.present?
    end

    def criteria
      @rubric.criteria
    end
  end
end
