# frozen_string_literal: true

# Assignment model
#
# Schema Information
#
# Table name: assignments
#
# id               :integer          not null, primary key
# user_id          :integer          not null, foreign key
# title            :string           not null
# subject          :string
# grade_level      :string
# instructions     :text             not null
# rubric_text      :text
# feedback_tone    :string           default("encouraging"), not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_assignments_on_user_id  (user_id)
#
class Assignment < ApplicationRecord
  has_prefix_id :asgn

  belongs_to :user
  has_many :selected_documents, dependent: :destroy
  has_many :student_works, dependent: :destroy

  has_one :rubric, dependent: :destroy
  has_one :assignment_summary, dependent: :destroy
  has_one :processing_metric, as: :processable, dependent: :destroy

  # Grade levels for assignment form
  GRADE_LEVELS = [ "5", "6", "7", "8", "9", "10", "11", "12", "university" ].freeze

  # Feedback tone options for assignment form
  FEEDBACK_TONES = [ "encouraging", "neutral/objective", "critical" ].freeze

  validates :title, presence: true
  validates :instructions, presence: true
  validates :grade_level, presence: true, inclusion: { in: GRADE_LEVELS }
  validates :feedback_tone, presence: true, inclusion: { in: FEEDBACK_TONES }
  validates :rubric_text, length: { maximum: 5000 }, allow_blank: true

  default_scope { order(created_at: :desc) }
end
