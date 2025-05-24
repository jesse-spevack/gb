# frozen_string_literal: true

# == Schema Information
#
# Table name: llm_requests
#
# id               :integer          not null, primary key
# trackable_type   :string           not null
# trackable_id     :integer          not null
# user_id          :integer          not null, foreign key
# llm              :integer          not null
# request_type     :integer          not null
# token_count      :integer          not null
# micro_usd        :integer          not null
# prompt           :text             not null
# created_at       :datetime         not null
# updated_at       :datetime         not null
# prefixed_id      :string
#
# Indexes
#
#  index_llm_requests_on_trackable  (trackable_type,trackable_id)
#  index_llm_requests_on_user_id    (user_id)
#
# Foreign Keys
#
#  llm_requests_user_id  (user_id => users.id)
#
class LLMRequest < ApplicationRecord
  has_prefix_id :llmrq

  belongs_to :user
  belongs_to :trackable, polymorphic: true

  validates :user, presence: true
  validates :trackable, presence: true
  validates :llm, presence: true
  validates :request_type, presence: true
  validates :token_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :micro_usd, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :prompt, presence: true

  enum :llm, { gemini_2_5_pro: 0, claude_3_7_sonnet: 1 }
  enum :request_type, { generate_rubric: 0, grade_student_work: 1 }

  def dollars
    micro_usd.to_f / 1_000_000
  end
end
