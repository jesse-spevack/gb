# frozen_string_literal: true

module PromptInput
  class AssignmentSummary
    def self.call(context:)
      build_and_attach_to_context(context)
    end

    def self.build_and_attach_to_context(context)
      Rails.logger.info("Building prompt input for assignment summary: #{context.assignment.id}")
      input = from(assignment: context.assignment)
      context.prompt = PromptTemplate.build("assignment_summary.txt.erb", input)
      context
    end

    def self.from(assignment:)
      new(assignment)
    end

    def initialize(assignment)
      @assignment = Assignment.includes(
        rubric: { criteria: :levels },
        student_works: [
          { student_criterion_levels: [ :criterion, :level ] },
          :feedback_items
        ]
      ).find(assignment.id)
    end

    def assignment_title
      @assignment.title
    end

    def assignment_subject
      @assignment.subject
    end

    def assignment_grade_level
      @assignment.grade_level
    end

    def assignment_instructions
      @assignment.instructions
    end

    def rubric
      @assignment.rubric
    end

    def student_works
      @assignment.student_works
    end

    def student_works_count
      @assignment.student_works.count
    end

    def rubric_criteria
      @assignment.rubric&.criteria || []
    end

    def rubric_performance_summary
      PromptInput::StudentPerformanceSummary.from(assignment: @assignment)
    end
  end
end
