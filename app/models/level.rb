# frozen_string_literal: true

# == Schema Information
#
# Table name: levels
#
# id               :integer          not null, primary key
# criterion_id     :integer          not null, foreign key
# title            :string           not null
# description      :text             not null
# performance_level:integer          not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
# points           :integer          not null
#
# Indexes
#
#  index_levels_on_criterion_id                        (criterion_id)
#  index_levels_on_criterion_id_and_points  (criterion_id,points) UNIQUE
#  index_levels_on_performance_level                   (performance_level)
class Level < ApplicationRecord
  belongs_to :criterion
  has_many :student_criterion_levels, dependent: :destroy

  # Define performance levels enum
  enum :performance_level, {
    exceeds: 0,
    meets: 1,
    approaching: 2,
    below: 3
  }

  validates :title, presence: true
  validates :description, presence: true
  validates :performance_level, presence: true
  validates :points, presence: true, numericality: { only_integer: true, in: 1..4 }
  validate :points_unique_within_criterion
  validate :points_match_performance_level

  # Order levels by performance_level (best to worst)
  default_scope { order(performance_level: :asc) }

  private

  def points_unique_within_criterion
    return unless criterion && points

    existing_level = Level.where(criterion: criterion, points: points).where.not(id: id).exists?
    errors.add(:points, "must be unique within criterion") if existing_level
  end

  def points_match_performance_level
    return unless performance_level && points

    expected_points = case performance_level.to_sym
    when :exceeds then 4
    when :meets then 3
    when :approaching then 2
    when :below then 1
    end

    if points != expected_points
      errors.add(:points, "must be #{expected_points} for #{performance_level} performance level")
    end
  end
end
