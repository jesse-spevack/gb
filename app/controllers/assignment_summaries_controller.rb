# frozen_string_literal: true

class AssignmentSummariesController < ApplicationController
  before_action :set_assignment_summary
  before_action :authorize_assignment_summary

  def show
    @assignment = @assignment_summary.assignment

    # Calculate performance metrics
    @performance_distribution = calculate_performance_distribution
    @criterion_performance = calculate_criterion_performance
    @overall_average = calculate_overall_average
  rescue => e
    Rails.logger.error "Error calculating assignment summary metrics: #{e.message}"
    @performance_distribution = {}
    @criterion_performance = []
    @overall_average = 0
  end

  private

  def set_assignment_summary
    @assignment_summary = AssignmentSummary.find(params[:id])
  end

  def authorize_assignment_summary
    redirect_to assignments_path, alert: "Assignment summary is not available." unless @assignment_summary.assignment.user_id == Current.user.id
  end

  def calculate_performance_distribution
    student_works = @assignment.student_works.includes(student_criterion_levels: :level)
    total_students = student_works.count

    return {} if total_students.zero?

    # Calculate average performance level per student
    performance_counts = { "exceeds" => 0, "meets" => 0, "approaching" => 0, "below" => 0 }

    student_works.each do |student_work|
      student_levels = student_work.student_criterion_levels.includes(:level)
      next if student_levels.empty?

      # Calculate average points for this student
      total_points = student_levels.sum { |scl| scl.level.points }
      average_points = total_points.to_f / student_levels.count

      # Determine performance level based on average
      performance_level = case average_points
      when 3.5..4.0 then "exceeds"
      when 2.5...3.5 then "meets"
      when 1.5...2.5 then "approaching"
      else "below"
      end

      performance_counts[performance_level] += 1
    end

    # Calculate percentages
    performance_counts.transform_values do |count|
      {
        count: count,
        percentage: ((count.to_f / total_students) * 100).round
      }
    end
  end

  def calculate_criterion_performance
    return [] unless @assignment.rubric&.criteria&.any?

    @assignment.rubric.criteria.includes(:levels, student_criterion_levels: :level).map do |criterion|
      student_criterion_levels = criterion.student_criterion_levels.includes(:level)
      next if student_criterion_levels.empty?

      # Calculate average score for this criterion
      total_points = student_criterion_levels.sum { |scl| scl.level.points }
      average_score = (total_points.to_f / student_criterion_levels.count).round(1)

      # Count performance levels for this criterion
      level_counts = { "exceeds" => 0, "meets" => 0, "approaching" => 0, "below" => 0 }

      student_criterion_levels.each do |scl|
        level_counts[scl.level.performance_level] += 1
      end

      total_count = student_criterion_levels.count
      level_percentages = level_counts.transform_values do |count|
        total_count > 0 ? ((count.to_f / total_count) * 100).round(1) : 0
      end

      {
        title: criterion.title,
        average_score: average_score,
        level_counts: level_counts,
        level_percentages: level_percentages,
        total_students: total_count
      }
    end.compact
  end

  def calculate_overall_average
    all_student_criterion_levels = StudentCriterionLevel.joins(student_work: :assignment)
                                                        .where(student_works: { assignment: @assignment })
                                                        .includes(:level)

    return 0 if all_student_criterion_levels.empty?

    total_points = all_student_criterion_levels.sum { |scl| scl.level.points }
    (total_points.to_f / all_student_criterion_levels.count).round(1)
  end
end
