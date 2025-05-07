# frozen_string_literal: true

class Google::DocsService
  def initialize(user)
    @user = user
    @token_service = Google::TokenService.new(user)
    @client = @token_service.create_google_docs_client
  end

  def append_content_to_document(doc_id, content)
    Rails.logger.warn("TODO: Implement append_content_to_document")
  end
end
