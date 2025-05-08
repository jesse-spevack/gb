# frozen_string_literal: true

class Google::PickerService
  Result = Struct.new(:picker_token, :oauth_token, :app_id)

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
    @token_service = Google::TokenService.new(user)
  end

  def call
    Result.new(
      picker_token: picker_token,
      oauth_token: @token_service.access_token,
      app_id: app_id
    )
  end

  private

  def picker_token
    ENV["GOOGLE_API_KEY"]
  end

  def client_id
    ENV["GOOGLE_CLIENT_ID"]
  end

  def app_id
    client_id.split(".").first
  end
end
