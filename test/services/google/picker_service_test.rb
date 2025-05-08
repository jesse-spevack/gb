# frozen_string_literal: true

require "test_helper"

class Google::PickerServiceTest < ActiveSupport::TestCase
  test "call returns picker token, oauth token, and app id" do
    user = users(:teacher)

    ENV["GOOGLE_API_KEY"] = "picker_token"
    ENV["GOOGLE_CLIENT_ID"] = "app_id.hello_world"

    mock_token_service = mock("token_service")
    mock_token_service.expects(:access_token).returns("oauth_token")

    Google::TokenService.expects(:new).with(user).returns(mock_token_service)

    picker_service = Google::PickerService.new(user)
    result = picker_service.call

    assert_equal "picker_token", result.picker_token
    assert_equal "oauth_token", result.oauth_token
    assert_equal "app_id", result.app_id
  end
end
