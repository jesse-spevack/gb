# frozen_string_literal: true

class StudentWork < ApplicationRecord
  has_prefix_id :swrk

  belongs_to :assignment
  belongs_to :selected_document

  validates :assignment, presence: true
  validates :selected_document, presence: true
end
