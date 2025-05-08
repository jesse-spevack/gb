# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"

class Google::DriveServiceTest < ActiveSupport::TestCase
  test "fetch_document_content returns content" do
    user = users(:teacher)

    mock_token_service = mock("token_service")
    mock_client = mock("client")
    mock_file = mock("file")
    mock_string_io = mock("string_io")

    Google::TokenService.expects(:new).with(user).returns(mock_token_service)
    mock_token_service.expects(:create_google_drive_client).returns(mock_client)
    mock_client.expects(:get_file).with("doc_id", fields: "id, name, mimeType").returns(mock_file)
    mock_file.expects(:mime_type).returns("application/vnd.google-apps.document")
    StringIO.expects(:new).returns(mock_string_io)
    mock_client.expects(:export_file).with("doc_id", "text/plain", download_dest: mock_string_io)
    mock_string_io.expects(:string).returns("here is my test content")
    mock_string_io.expects(:close)

    drive_service = Google::DriveService.new(user)
    result = drive_service.fetch_document_content("doc_id")

    assert_equal "here is my test content", result
  end
end
