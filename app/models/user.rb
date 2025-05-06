# frozen_string_literal: true

# User model
#
# Schema Information
#
# Table name: users
#
# id                   :integer          not null, primary key
# email                :string           not null, indexed, unique
# name                 :string           not null
# google_uid           :string           not null, indexed, unique
# profile_picture_url  :string
# admin                :boolean          default(false)
# created_at           :datetime         not null
# updated_at           :datetime         not null
#
class User < ApplicationRecord
  has_prefix_id :usr

  has_many :user_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :llm_requests

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true

  def admin?
    admin
  end
end
