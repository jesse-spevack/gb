# frozen_string_literal: true

# == Schema Information
#
# Table name: feedback_items
#
# id                :integer          not null, primary key
# feedbackable_type :string           not null
# feedbackable_id   :integer          not null
# item_type         :integer          not null
# title             :string           not null
# description       :text             not null
# evidence          :text             not null
# created_at        :datetime         not null
# updated_at        :datetime         not null
#
# Indexes
#
#  index_feedback_items_on_feedbackable  (feedbackable_type,feedbackable_id)
#
class FeedbackItem < ApplicationRecord
  enum :item_type, { strength: 0, opportunity: 1 }

  belongs_to :feedbackable, polymorphic: true

  validates :title, presence: true
  validates :description, presence: true
  validates :evidence, presence: true
  validates :item_type, presence: true

  scope :strengths, -> { where(item_type: :strength) }
  scope :opportunities, -> { where(item_type: :opportunity) }

  default_scope { order(created_at: :desc) }
end
