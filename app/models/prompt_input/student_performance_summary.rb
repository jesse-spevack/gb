# frozen_string_literal: true

module PromptInput
  class StudentPerformanceSummary
    def self.from(assignment:)
      new(assignment).build
    end

    def initialize(assignment)
      @assignment = assignment
      @student_criterion_levels = StudentCriterionLevel.includes(:criterion, :level)
        .where(student_work: @assignment.student_works)
        .group_by(&:criterion)
    end

    def build
      @student_criterion_levels.map do |criterion, student_criterion_levels|
        positions = student_criterion_levels.map(&:level).map(&:position)
        average = positions.sum.to_f / positions.size

        PromptInput::CriterionPerformanceSummary.new(
          criterion_title: criterion.title,
          average_level: average,
          min_level: positions.min,
          max_level: positions.max,
          count: student_criterion_levels.count
        )
      end
    end
  end
end
