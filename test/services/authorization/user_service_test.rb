class Authorization::UserServiceTest < ActiveSupport::TestCase
  test "user_from_google_auth creates a new user if one doesn't exist" do
    freeze_time do
      auth = {
        "uid" => "123456789",
        "info" => {
          "email" => "test@example.com",
          "name" => "Test User",
          "image" => "https://example.com/image.jpg"
        },
        "credentials" => {
          "token" => "test_token",
          "refresh_token" => "test_refresh_token",
          "expires_at" => Time.current + 5.minutes
        }
      }

      user = Authorization::UserService.user_from_google_auth(auth)

      assert_equal "test@example.com", user.email
      assert_equal "Test User", user.name
      assert_equal "https://example.com/image.jpg", user.profile_picture_url
      assert_equal "test_token", user.user_tokens.first.access_token
      assert_equal "test_refresh_token", user.user_tokens.first.refresh_token
      assert_equal Time.current + 5.minutes, user.user_tokens.first.expires_at
    end
  end

  test "user_from_google_auth updates an existing user if one exists" do
    freeze_time do
      user = users(:admin)
      auth = {
        "uid" => user.google_uid,
        "info" => {
          "email" => "test@example.com",
          "name" => "Test User",
          "image" => "https://example.com/image.jpg"
        },
        "credentials" => {
          "token" => "test_token",
          "refresh_token" => "test_refresh_token",
          "expires_at" => Time.current + 5.minutes
        }
      }

      user = Authorization::UserService.user_from_google_auth(auth)

      assert_equal "test@example.com", user.email
      assert_equal "Test User", user.name
      assert_equal "https://example.com/image.jpg", user.profile_picture_url
      assert_equal "test_token", user.user_tokens.first.access_token
      assert_equal "test_refresh_token", user.user_tokens.first.refresh_token
      assert_equal Time.current + 5.minutes, user.user_tokens.first.expires_at
    end
  end
end
