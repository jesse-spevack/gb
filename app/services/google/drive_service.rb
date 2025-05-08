# frozen_string_literal: true

class Google::DriveService
  def initialize(user)
    @user = user
    @token_service = Google::TokenService.new(user)
    @client = @token_service.create_google_drive_client
  end

  def fetch_document_content(doc_id)
    file = @client.get_file(doc_id, fields: "id, name, mimeType")

    case file.mime_type
    when "application/vnd.google-apps.document"
      string_io = StringIO.new
      @client.export_file(doc_id, "text/plain", download_dest: string_io)
      content = string_io.string
      string_io.close
      content
    else
      raise "Unsupported mime type: #{file.mime_type}"
    end
  end
end
