require "test_helper"

class RubricTest < ActiveSupport::TestCase
  test "is not valid without assignment" do
    rubric = Rubric.new
    assert_not rubric.valid?
  end

  test "is valid with assignment" do
    rubric = Rubric.new(assignment: assignments(:english_essay))
    assert rubric.valid?
  end
end
