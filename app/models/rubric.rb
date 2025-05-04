# frozen_string_literal: true

# == Schema Information
#
# Table name: rubrics
#
# id               :integer          not null, primary key
# assignment_id    :integer          not null, foreign key
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_rubrics_on_assignment_id  (assignment_id)
#
class Rubric < ApplicationRecord
  has_prefix_id :rbrc

  belongs_to :assignment

  validates :assignment, presence: true
end
