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

  def high_level_feedback_average
    assigned_levels = student_criterion_levels.map(&:level)
    grouped_levels = assigned_levels.reduce(Hash.new(0)) do |acc, level|
      acc[level.title] += 1
      acc
    end
    grouped_levels.max_by { |_, count| count }[0]
  end
end
