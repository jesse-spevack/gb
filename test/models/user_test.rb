require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not be valid without email" do
    user = User.new(name: "Test User", google_uid: "123456")
    assert_not user.valid?
  end

  test "should not be valid without name" do
    user = User.new(email: "test@example.com", google_uid: "123456")
    assert_not user.valid?
  end

  test "should not be valid without google_uid" do
    user = User.new(email: "test@example.com", name: "Test User")
    assert_not user.valid?
  end

  test "should be valid with email, name, and google_uid" do
    user = User.new(email: "test@example.com", name: "Test User", google_uid: "123456")
    assert user.valid?
  end

  test "#admin? returns true if admin is true" do
    user = User.new(email: "test@example.com", name: "Test User", google_uid: "123456", admin: true)
    assert user.admin?
  end

  test "#admin? returns false if admin is false" do
    user = User.new(email: "test@example.com", name: "Test User", google_uid: "123456", admin: false)
    assert_not user.admin?
  end
end
