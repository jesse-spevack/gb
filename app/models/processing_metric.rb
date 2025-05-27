# frozen_string_literal: true

class ProcessingMetric < ApplicationRecord
  belongs_to :processable, polymorphic: true
  belongs_to :assignment, optional: true
  belongs_to :user, optional: true

  validates :processable, presence: true
  validates :status, presence: true
  validates :total_duration_ms, presence: true, if: :completed?

  before_save :set_associations

  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2
  }

  scope :for_assignment, ->(assignment) {
    where(assignment: assignment)
  }

  scope :for_user, ->(user) {
    where(user: user)
  }

  scope :completed, -> { where(status: :completed) }

  def self.average_total_duration
    completed.average(:total_duration_ms)&.to_i || 0
  end

  def self.average_llm_duration
    completed.average(:llm_duration_ms)&.to_i || 0
  end

  private

  def set_associations
    self.recorded_at ||= Time.current

    # Set assignment reference for easier querying
    case processable
    when Assignment
      self.assignment = processable
      self.user = processable.user
    when Rubric
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    when StudentWork
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    when AssignmentSummary
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    end
  end
end
