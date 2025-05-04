# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_summaries
#
# id                   :integer          not null, primary key
# assignment_id        :integer          not null, foreign key
# student_work_count   :integer          not null
# qualitative_insights :text             not null
# created_at           :datetime         not null
# updated_at           :datetime         not null
# prefixed_id          :string
#
# Indexes
#
#  index_assignment_summaries_on_assignment_id  (assignment_id)
#  index_assignment_summaries_on_prefixed_id    (prefixed_id) UNIQUE
#
# Foreign Keys
#
#  assignment_id  (assignment_id => assignments.id)
#
class AssignmentSummary < ApplicationRecord
  has_prefix_id :sum

  belongs_to :assignment
  has_many :feedback_items, as: :feedbackable, dependent: :destroy

  validates :student_work_count, presence: true
  validates :qualitative_insights, presence: true
end
