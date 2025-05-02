# frozen_string_literal: true

# UserToken model

# == Schema Information
#
# Table name: user_tokens
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  access_token  :string
#  refresh_token :string
#  expires_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_user_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class UserToken < ApplicationRecord
  belongs_to :user

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  # Scope to order by created_at desc, so the most recent token is first
  default_scope { order(created_at: :desc) }

  EXPIRY_BUFFER = 5.minutes

  def expired?
    expires_at <= Time.current
  end

  def will_expire_soon?
    expires_at <= (Time.current + EXPIRY_BUFFER)
  end

  def self.most_recent_for(user:)
    user.user_tokens.first
  end
end
