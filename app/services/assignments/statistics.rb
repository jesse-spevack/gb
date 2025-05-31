# frozen_string_literal: true

module Assignments
  # Service for calculating assignment statistics including criterion performance averages
  class Statistics
    # Struct to hold criterion performance statistics
    CriterionStats = Struct.new(:average, :evaluated_count, :total_count, keyword_init: true)

    # Stats collection object that provides access to criterion statistics
    class StatsCollection
      def initialize(stats_hash)
        @stats_hash = stats_hash
      end

      def for(criterion)
        @stats_hash[criterion]
      end

      def empty?
        @stats_hash.empty?
      end
    end

    def self.get_criterion_performance(assignment)
      new(assignment).criterion_performance
    end

    def initialize(assignment)
      @assignment = assignment
    end

    # Get performance statistics for all criteria
    # Returns a StatsCollection object
    def criterion_performance
      return StatsCollection.new({}) unless @assignment.rubric

      stats_hash = @assignment.rubric.criteria.each_with_object({}) do |criterion, stats|
        stats[criterion] = calculate_criterion_stats(criterion)
      end

      StatsCollection.new(stats_hash)
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

      CriterionStats.new(
        average: calculate_average(student_criterion_levels),
        evaluated_count: evaluated_count,
        total_count: total_count
      )
    end

    def calculate_average(student_criterion_levels)
      return nil if student_criterion_levels.empty?

      total_points = student_criterion_levels.joins(:level).sum("levels.points")
      count = student_criterion_levels.count

      (total_points.to_f / count).round(2)
    end
  end
end
