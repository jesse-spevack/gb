require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "session not valid without user" do
    session = Session.new(user_agent: "test", ip_address: "test")
    assert_not session.valid?
  end

  test "session not valid without user agent" do
    session = Session.new(user: users(:admin), ip_address: "test")
    assert_not session.valid?
  end

  test "session not valid without ip address" do
    session = Session.new(user: users(:admin), user_agent: "test")
    assert_not session.valid?
  end
end
