# frozen_string_literal: true

# == Schema Information
#
# Table name: criteria
#
# id               :integer          not null, primary key
# rubric_id        :integer          not null, foreign key
# title            :string           not null
# description      :text             not null
# position         :integer          not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_criteria_on_rubric_id  (rubric_id)
#
class Criterion < ApplicationRecord
  belongs_to :rubric

  validates :title, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }

  default_scope { order(position: :asc) }
end
