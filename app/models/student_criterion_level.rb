# frozen_string_literal: true

# == Schema Information
#
# Table name: student_criterion_levels
#
# id               :integer          not null, primary key
# student_work_id  :integer          not null, foreign key
# criterion_id     :integer          not null, foreign key
# level_id         :integer          not null, foreign key
# explanation      :text             not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_student_criterion_levels_on_criterion_id     (criterion_id)
#  index_student_criterion_levels_on_level_id         (level_id)
#  index_student_criterion_levels_on_student_work_id  (student_work_id)
#
class StudentCriterionLevel < ApplicationRecord
  belongs_to :student_work
  belongs_to :criterion
  belongs_to :level

  validates :explanation, presence: true
  validate :level_must_belong_to_criterion

  private

  def level_must_belong_to_criterion
    return unless criterion.present? && level.present?

    unless level.criterion_id == criterion.id
      errors.add(:level, "must belong to the selected criterion")
    end
  end
end
