# frozen_string_literal: true

require "test_helper"

class Google::TokenServiceTest < ActiveSupport::TestCase
  def setup
    ENV["GOOGLE_CLIENT_ID"] = "GOOGLE_CLIENT_ID"
    ENV["GOOGLE_CLIENT_SECRET"] = "GOOGLE_CLIENT_SECRET"

    @user = users(:teacher)

    @credentials = mock("credentials")
    Google::Auth::UserRefreshCredentials.expects(:new).with(
      client_id: "GOOGLE_CLIENT_ID",
      client_secret: "GOOGLE_CLIENT_SECRET",
      refresh_token: user_tokens(:one).refresh_token
    ).returns(@credentials)
  end

  test "create_google_drive_client returns client" do
    service = mock("service")
    Google::Apis::DriveV3::DriveService.expects(:new).returns(service)
    service.expects(:authorization=).with(@credentials)

    result = Google::TokenService.new(@user).create_google_drive_client

    assert_equal service, result
  end

  test "create_google_docs_client returns client" do
    service = mock("service")
    Google::Apis::DocsV1::DocsService.expects(:new).returns(service)
    service.expects(:authorization=).with(@credentials)

    result = Google::TokenService.new(@user).create_google_docs_client

    assert_equal service, result
  end

  test "access_token returns access token when credentials access token has not expired" do
    @credentials.stubs(:access_token_expired?).returns(false)
    @credentials.stubs(:access_token).returns("access_token")

    result = Google::TokenService.new(@user).access_token

    assert_equal "access_token", result
  end

  test "access_token returns access token when credentials access token has expired" do
    freeze_time do
      @credentials.stubs(:access_token_expired?).returns(true)
      @credentials.stubs(:fetch_access_token!)
      @credentials.stubs(:access_token).returns("access_token")
      @credentials.stubs(:expires_in).returns(1_000)

      result = Google::TokenService.new(@user).access_token

      assert_equal "access_token", result
      assert_equal "access_token", UserToken.most_recent_for(user: @user).access_token
      assert_equal Time.current + 1_000.seconds, UserToken.most_recent_for(user: @user).expires_at
    end
  end
end
