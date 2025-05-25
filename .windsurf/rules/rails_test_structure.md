---
trigger: model_decision
description: Guidelines for test structure
globs: test/*
---
# Rails Test Structure

- **Combine Related Assertions**
  - Group related `assert_difference` statements to reduce nesting
  - Focus tests on outputs and side effects, not implementation details
  
  ```ruby
  # ✅ DO: Combine related assertions for conciseness
  test "creates assignment with associated records" do
    assert_difference [ "Assignment.count", "SelectedDocument.count", "StudentWork.count", "Rubric.count" ], 1 do
      result = Assignments::CreationService.create(@assignment_input)
      # Assertions on the result...
    end
  end
  
  # ❌ DON'T: Use deeply nested test blocks
  # test "creates assignment with associated records" do
  #   assert_difference "Assignment.count", 1 do
  #     assert_difference "SelectedDocument.count", 1 do
  #       assert_difference "StudentWork.count", 1 do
  #         assert_difference "Rubric.count", 1 do
  #           result = Assignments::CreationService.create(@assignment_input)
  #           # Assertions on the result...
  #         end
  #       end
  #     end
  #   end
  # end
  ```

- **Direct Assertion Naming**
  - Test names should clearly state what is being tested
  - Use active verbs like "creates", "updates", "raises" in test names
  
  ```ruby
  # ✅ DO: Use direct, active verbs in test names
  test "raises error when assignment not found" do
    # Test logic...
  end
  
  # ❌ DON'T: Use passive or vague test names
  # test "should handle missing assignment case" do
  #   # Test logic...
  # end
  ```

- **Test Isolation**
  - Set up test data directly in the test or setup method
  - Use mocks and stubs for cleaner test isolation
  
  ```ruby
  # ✅ DO: Use mocks/stubs for clean isolation
  test "returns failure when error occurs" do
    SelectedDocument::BulkCreationService.stubs(:create).raises(StandardError.new("Test error"))
    
    result = Assignments::CreationService.create(@assignment_input)
    assert_equal "Test error", result.error_message
  end
  
  # ❌ DON'T: Test methods by relying on side effects
  # test "fails when documents can't be created" do
  #   # Call service while hoping documents fail to create naturally
  #   # This makes the test fragile and dependent on implementation
  # end
  ```
