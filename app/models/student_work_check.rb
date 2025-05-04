# frozen_string_literal: true

# == Schema Information
#
# Table name: student_work_checks
#
# id               :integer          not null, primary key
# student_work_id  :integer          not null, foreign key
# check_type       :integer          not null
# score            :integer          not null
# explanation      :text             not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_student_work_checks_on_student_work_id  (student_work_id)
#
# Foreign Keys
#
#  student_work_id  (student_work_id => student_works.id)
#
class StudentWorkCheck < ApplicationRecord
  belongs_to :student_work

  validates :student_work, presence: true
  validates :check_type, presence: true
  validates :score, presence: true
  validates :explanation, presence: true

  enum :check_type, { plagiarism: 0, llm_generated: 1 }
end
