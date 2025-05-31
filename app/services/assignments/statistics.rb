# frozen_string_literal: true

module Assignments
  # Service for calculating assignment statistics including criterion performance averages
  class Statistics
    def initialize(assignment)
      @assignment = assignment
    end

    # Get performance statistics for all criteria
    # Returns a hash with criterion as key and stats as value
    def criterion_performance
      return {} unless @assignment.rubric

      @assignment.rubric.criteria.each_with_object({}) do |criterion, stats|
        stats[criterion] = calculate_criterion_stats(criterion)
      end
    end

    private

    def calculate_criterion_stats(criterion)
      student_criterion_levels = StudentCriterionLevel
        .joins(:student_work)
        .where(
          criterion: criterion,
          student_works: { assignment_id: @assignment.id }
        )

      evaluated_count = student_criterion_levels.count
      total_count = @assignment.student_works.count

      {
        average: calculate_average(student_criterion_levels),
        evaluated_count: evaluated_count,
        total_count: total_count
      }
    end

    def calculate_average(student_criterion_levels)
      return nil if student_criterion_levels.empty?

      total_points = student_criterion_levels.joins(:level).sum("levels.points")
      count = student_criterion_levels.count

      (total_points.to_f / count).round(2)
    end
  end
end