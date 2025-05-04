# frozen_string_literal: true

# == Schema Information
#
# Table name: levels
#
# id               :integer          not null, primary key
# criterion_id     :integer          not null, foreign key
# title            :string           not null
# description      :text             not null
# position         :integer          not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_levels_on_criterion_id  (criterion_id)
class Level < ApplicationRecord
  belongs_to :criterion

  validates :title, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Order levels by position (highest achievement level first)
  default_scope { order(position: :asc) }
end
