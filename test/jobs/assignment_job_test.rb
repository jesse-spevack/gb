require "test_helper"

class AssignmentJobTest < ActiveJob::TestCase
  test "logs warning for pending implementation" do
    assignment = assignments(:english_essay)

    Rails.logger.expects(:warn).with(
      "AssignmentJob: Called for Assignment #{assignment.id} (#{assignment.title}) but implementation is pending"
    )

    AssignmentJob.perform_now(assignment.id)
  end

  test "raises error when assignment not found" do
    nonexistent_id = 999999

    assert_raises(ActiveRecord::RecordNotFound) do
      AssignmentJob.perform_now(nonexistent_id)
    end
  end
end
