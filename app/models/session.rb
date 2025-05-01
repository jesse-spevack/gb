# frozen_string_literal: true

# Session model
#
# Schema Information
#
# Table name: sessions
#
# id                   :integer          not null, primary key
# user_id              :integer          not null, indexed, foreign key
# user_agent           :string           not null
# ip_address           :string           not null
# created_at           :datetime         not null
# updated_at           :datetime         not null
#
class Session < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
  validates :user_agent, presence: true
  validates :ip_address, presence: true
end
