# frozen_string_literal: true

require "test_helper"

class Google::DocsServiceTest < ActiveSupport::TestCase
  test "append_content_to_document returns true" do
    result = Google::DocsService.new(users(:teacher)).append_content_to_document("doc_id", "content")
    assert_equal true, result
  end
end
