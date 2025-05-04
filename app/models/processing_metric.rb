# frozen_string_literal: true

class ProcessingMetric < ApplicationRecord
  belongs_to :processable, polymorphic: true

  validates :processable, presence: true
  validates :status, presence: true

  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2
  }
end
