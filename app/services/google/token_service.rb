# frozen_string_literal: true

class Google::TokenService
  class NoValidTokenError < StandardError; end

  def initialize(user)
    @user = user
  end

  def create_google_drive_client
    # Gem google-apis-drive_v3
    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = create_credentials
    service
  end

  def create_google_docs_client
    # Gem google-apis-docs_v1
    service = Google::Apis::DocsV1::DocsService.new
    service.authorization = create_credentials
    service
  end

  def access_token
    credentials = create_credentials

    if credentials.access_token_expired?
      credentials.fetch_access_token!

      token = get_valid_token
      token.update(
        access_token: credentials.access_token,
        expires_at: Time.current + credentials.expires_in.seconds
      )
    end

    credentials.access_token
  end

  private

  def create_credentials
    token = get_valid_token

    # Gem googleauth
    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      refresh_token: token.refresh_token
    )
  end

  def get_valid_token
    token = UserToken.most_recent_for(user: @user)
    return token if token.valid?

    raise NoValidTokenError, "No valid token found for user #{@user.id}" if token.nil?

    token
  end
end
