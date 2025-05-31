# frozen_string_literal: true

module Authorization
  # Service object for handling user authentication
  class UserService
    def self.user_from_google_auth(auth)
      user = User.find_or_initialize_by(google_uid: auth["uid"])
      user.assign_attributes(
        email: auth["info"]["email"],
        name: auth["info"]["name"],
        profile_picture_url: auth["info"]["image"]&.split("=")&.first, # Remove any existing size params
      )
      user.save!

      if auth["credentials"].present?
        user.user_tokens.create!(
          access_token: auth["credentials"]["token"],
          refresh_token: auth["credentials"]["refresh_token"],
          expires_at: auth["credentials"]["expires_at"]
        )
      end

      user
    end
  end
end
