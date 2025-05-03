require "test_helper"

class SelectedDocumentTest < ActiveSupport::TestCase
  test "is not valid without assignment" do
    selected_document = SelectedDocument.new(google_doc_id: "test_id", title: "test_title", url: "test_url")
    assert_not selected_document.valid?
  end

  test "is not valid without google_doc_id" do
    selected_document = SelectedDocument.new(assignment: assignments(:english_essay), title: "test_title", url: "test_url")
    assert_not selected_document.valid?
  end

  test "is not valid without title" do
    selected_document = SelectedDocument.new(assignment: assignments(:english_essay), google_doc_id: "test_id", url: "test_url")
    assert_not selected_document.valid?
  end

  test "is not valid without url" do
    selected_document = SelectedDocument.new(assignment: assignments(:english_essay), google_doc_id: "test_id", title: "test_title")
    assert_not selected_document.valid?
  end

  test "is valid with all required attributes" do
    selected_document = SelectedDocument.new(assignment: assignments(:english_essay), google_doc_id: "test_id", title: "test_title", url: "test_url")
    assert selected_document.valid?
  end
end
