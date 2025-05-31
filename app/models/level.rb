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
# points           :integer          not null
#
# Indexes
#
#  index_levels_on_criterion_id                        (criterion_id)
#  index_levels_on_criterion_id_and_points  (criterion_id,points) UNIQUE
class Level < ApplicationRecord
  belongs_to :criterion
  has_many :student_criterion_levels, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :points, presence: true, numericality: { only_integer: true, in: 0..4 }
  validate :points_unique_within_criterion

  # Order levels by position (highest achievement level first)
  default_scope { order(position: :asc) }

  private

  def points_unique_within_criterion
    return unless criterion && points

    existing_level = Level.where(criterion: criterion, points: points).where.not(id: id).exists?
    errors.add(:points, "must be unique within criterion") if existing_level
  end
end
