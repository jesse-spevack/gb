require "test_helper"

class DocumentDataTest < ActiveSupport::TestCase
  test "correctly maps JSON to data" do
    document_data = DocumentData.from_json('[{"googleDocId": "1", "title": "Document 1", "url": "https://example.com/1"}]')
    assert_equal 1, document_data.length
    assert_equal "1", document_data.first.google_doc_id
    assert_equal "Document 1", document_data.first.title
    assert_equal "https://example.com/1", document_data.first.url
  end

  test "returns empty array if JSON is invalid" do
    document_data = DocumentData.from_json("invalid json")
    assert_equal [], document_data
  end

  test "empty? returns true if data is empty" do
    document_data = DocumentData.from_json("[]")
    assert document_data.empty?
  end
end
