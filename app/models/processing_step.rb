class ProcessingStep < ApplicationRecord
  belongs_to :assignment

  STEP_KEYS = [
    "assignment_saved",
    "creating_rubric",
    "generating_feedback",
    "summarizing_feedback"
  ].freeze

  enum :status, { pending: 0, in_progress: 1, completed: 2 }

  validates :step_key, presence: true, inclusion: { in: STEP_KEYS }
  validates :step_key, uniqueness: { scope: :assignment_id }

  scope :ordered, -> { order(:id) }
end
