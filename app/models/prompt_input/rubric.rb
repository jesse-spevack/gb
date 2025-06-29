# frozen_string_literal: true

module PromptInput
  class Rubric
    def self.call(context:)
      build_and_attach_to_context(context)
    end

    def self.build_and_attach_to_context(context)
      Rails.logger.info("Building prompt input for rubric generation: #{context.assignment.id}")
      context.prompt = build_prompt(context.assignment)
      context
    end

    def self.build_prompt(assignment)
      input = RubricPromptInput.from(assignment: assignment)
      PromptTemplate.build("rubric_generation.txt.erb", input)
    end

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
