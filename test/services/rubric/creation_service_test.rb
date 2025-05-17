require "test_helper"

class Rubric::CreationServiceTest < ActiveSupport::TestCase
  test "creates a rubric for an assignment" do
    assignment = assignments(:english_essay)

    assert_difference "Rubric.count" do
      result = Rubric::CreationService.create(assignment: assignment)

      assert result.success?
      assert_not_nil result.rubric
      assert_equal assignment, result.rubric.assignment
    end
  end

  test "raises error when assignment is nil" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Rubric::CreationService.create(assignment: nil)
    end
  end
end
