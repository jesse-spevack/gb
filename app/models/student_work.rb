# frozen_string_literal: true

class StudentWork < ApplicationRecord
  has_prefix_id :swrk

  has_many :student_criterion_levels, dependent: :destroy
  has_many :student_work_checks, dependent: :destroy
  has_many :feedback_items, as: :feedbackable
  has_many :llm_requests, as: :trackable

  has_one :processing_metric, as: :processable, dependent: :destroy

  belongs_to :assignment
  belongs_to :selected_document

  validates :assignment, presence: true
  validates :selected_document, presence: true

  # Returns the average performance level as a string (e.g., "Meets")
  def high_level_feedback_average
    return nil if student_criterion_levels.empty?

    avg_points = average_performance_points
    return nil if avg_points.nil?

    # Round to nearest whole number and map to performance level
    rounded_points = avg_points.round

    case rounded_points
    when 4
      "Exceeds"
    when 3
      "Meets"
    when 2
      "Approaching"
    when 1
      "Below"
    else
      "Meets" # Default for edge cases
    end
  end

  # Returns the numeric average of performance points as a float
  def average_performance_points
    return nil if student_criterion_levels.empty?

    # Get all levels with their points
    levels_with_points = student_criterion_levels.includes(:level).map(&:level).compact
    return nil if levels_with_points.empty?

    # Calculate average points
    total_points = levels_with_points.sum(&:points)
    total_points.to_f / levels_with_points.count
  end
end
