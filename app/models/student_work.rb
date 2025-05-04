# frozen_string_literal: true

class StudentWork < ApplicationRecord
  has_prefix_id :swrk

  has_many :student_criterion_levels, dependent: :destroy
  has_many :feedback_items, as: :feedbackable
  has_many :llm_requests, as: :trackable

  has_one :processing_metric, as: :processable, dependent: :destroy

  belongs_to :assignment
  belongs_to :selected_document

  validates :assignment, presence: true
  validates :selected_document, presence: true
end
