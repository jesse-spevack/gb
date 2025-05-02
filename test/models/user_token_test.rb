require "test_helper"

class UserTokenTest < ActiveSupport::TestCase
  test "most_recent_for returns the most recent token for a user" do
    user = users(:admin)
    token = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + 1.day)
    assert_equal token, UserToken.most_recent_for(user: user)
  end

  test "most_recent_for returns nil if no tokens exist for a user" do
    user = users(:admin)
    assert_nil UserToken.most_recent_for(user: user)
  end

  test "validates presence of access_token, refresh_token, and expires_at" do
    user = users(:admin)
    token = user.user_tokens.build
    assert_not token.valid?
    assert_equal [ "can't be blank" ], token.errors[:access_token]
    assert_equal [ "can't be blank" ], token.errors[:refresh_token]
    assert_equal [ "can't be blank" ], token.errors[:expires_at]
  end

  test "Default scope orders tokens by created_at desc" do
    user = users(:admin)
    token1 = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + 1.day)
    token2 = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + 2.days)
    assert_equal [ token2, token1 ], user.user_tokens
  end

  test "expired? returns true if the token has expired" do
    user = users(:admin)
    token = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current - 1.day)
    assert token.expired?
  end

  test "expired? returns false if the token has not expired" do
    user = users(:admin)
    token = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + 1.day)
    assert_not token.expired?
  end

  test "will_expire_soon? returns true if the token will expire soon" do
    user = users(:admin)
    token = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + UserToken::EXPIRY_BUFFER - 1.second)
    assert token.will_expire_soon?
  end

  test "will_expire_soon? returns false if the token will not expire soon" do
    user = users(:admin)
    token = user.user_tokens.create(access_token: "test", refresh_token: "test", expires_at: Time.current + UserToken::EXPIRY_BUFFER + 1.second)
    assert_not token.will_expire_soon?
  end
end
