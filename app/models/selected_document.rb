# frozen_string_literal: true

# == Schema Information
#
# Table name: selected_documents
#
# id               :integer          not null, primary key
# assignment_id    :integer          not null, foreign key
# google_doc_id    :string           not null
# title            :string           not null
# url              :string           not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
#
# Indexes
#
#  index_selected_documents_on_assignment_id  (assignment_id)
#
class SelectedDocument < ApplicationRecord
  belongs_to :assignment

  validates :assignment, presence: true
  validates :google_doc_id, presence: true
  validates :title, presence: true
  validates :url, presence: true
end
