# frozen_string_literal: true

# == Schema Information
#
# Table name: llm_usage_records
#
# id               :integer          not null, primary key
# trackable_type   :string           not null
# trackable_id     :integer          not null
# user_id          :integer          not null, foreign key
# llm_provider     :integer          not null
# request_type     :integer          not null
# token_count      :integer          not null
# micro_usd        :integer          not null
# llm_model        :string           not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
# prefixed_id      :string
#
# Indexes
#
#  index_llm_usage_records_on_trackable  (trackable_type,trackable_id,created_at)
#  index_llm_usage_records_on_user_id    (user_id,created_at)
#  index_llm_usage_records_on_llm_model  (llm_model)
#  index_llm_usage_records_on_created_at (created_at)
#
# Foreign Keys
#
#  llm_usage_records_user_id  (user_id => users.id)
#
class LLMUsageRecord < ApplicationRecord
  has_prefix_id :llmur

  belongs_to :user
  belongs_to :trackable, polymorphic: true

  validates :user, presence: true
  validates :trackable, presence: true
  validates :llm_provider, presence: true
  validates :request_type, presence: true
  validates :llm_model, presence: true
  validates :token_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :micro_usd, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :llm_provider, { google: 0, anthropic: 1 }
  enum :request_type, { generate_rubric: 0, grade_student_work: 1 }

  def dollars
    micro_usd.to_f / 1_000_000
  end
end
