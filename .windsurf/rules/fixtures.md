---
trigger: manual
description:
globs:
---
- **Fixture Validity:**
  - Avoid creating fixtures that represent invalid model states, especially if they violate database constraints (`null: false`, `uniqueness`).
  - Fixture loading happens *before* tests run, and database constraints are checked during loading. Invalid fixtures will cause errors before any tests execute.
  - Test model validations (e.g., `validates :presence`) by creating invalid objects directly within the test using `Model.new` or `Model.create`, not by relying on invalid fixtures.

  ```ruby
  # ✅ DO: Test validation by creating an invalid object in the test
  test "invalid without title" do
    # Setup
    rubric = rubrics(:valid_rubric)
    # Exercise
    criterion = Criterion.new(description: "Test Description", rubric: rubric) 
    # Verify
    assert_not criterion.valid?
    assert_includes criterion.errors[:title], "can't be blank"
  end
  
  # ❌ DON'T: Create fixtures that violate database constraints
  # In test/fixtures/criteria.yml:
  # invalid_criterion_no_title:
  #   description: "This criterion is missing a title." # Fails if title has NOT NULL constraint
  #   position: 3
  #   rubric: valid_rubric
  ```

- **Reference Existing Rules:**
  - For general testing structure and fixture usage conventions, see [test.mdc](mdc:.cursor/rules/test.mdc).
