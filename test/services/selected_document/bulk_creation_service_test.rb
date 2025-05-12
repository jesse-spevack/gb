require "test_helper"

class SelectedDocument::BulkCreationServiceTest < ActiveSupport::TestCase
  test "creates student works" do
    assignment = assignments(:english_essay_with_rubric_text)
    raw_document_data = [
      { googleDocId: "test_google_doc_id", title: "Test Document", url: "https://example.com/test_document" },
      { googleDocId: "test_google_doc_id_2", title: "Test Document 2", url: "https://example.com/test_document_2" }
    ]

    json_document_data = raw_document_data.to_json

    document_data = DocumentData.from_json(json_document_data)

    original_count = SelectedDocument.count

    SelectedDocument::BulkCreationService.create(assignment: assignment, document_data: document_data)

    assert_equal original_count + 2, SelectedDocument.count
  end
end
