## Relevant Files

- `app/models/level.rb` - Main Level model that needs point field and validations
- `test/models/level_test.rb` - Unit tests for Level model validations and functionality
- `db/migrate/[timestamp]_add_points_to_levels.rb` - Migration to add points field to levels table
- `app/models/assignment.rb` - Assignment model that will calculate criterion averages
- `test/models/assignment_test.rb` - Unit tests for assignment average calculations
- `app/views/assignments/show.html.erb` - Assignment show page to display criterion averages
- `app/controllers/assignments_controller.rb` - Controller to prepare average data for view
- `test/controllers/assignments_controller_test.rb` - Controller tests for average calculations
- `app/models/rubric.rb` - May need updates for level point assignment logic
- `test/models/rubric_test.rb` - Tests for rubric level point assignment
- `app/services/rubric/creation_service.rb` - Service that creates rubrics and levels
- `test/services/rubric/creation_service_test.rb` - Tests for automatic point assignment

### Notes

- Unit tests should typically be placed alongside the code files they are testing (e.g., `my_class.rb` and `my_class_test.rb` in the `test` directory).
- Use `bin/rails test [optional/path/to/test/file]` to run tests. Running without a path executes all tests.

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 |  | ws1 | 🟡 pending | Add points field to Level model | Create database migration and update Level model with points field | [Details 1.0](#task-1.0) |
| 2.0 |  | ws1 | 🟡 pending | Implement Level model validations | Add validations for points field including range and uniqueness constraints | [Details 2.0](#task-2.0) |
| 3.0 |  | ws1 | 🟡 pending | Implement automatic point assignment | Update rubric/level creation logic to automatically assign points 0-4 | [Details 3.0](#task-3.0) |
| 4.0 |  | ws1 | 🟡 pending | Add criterion average calculations | Implement methods to calculate average performance per criterion | [Details 4.0](#task-4.0) |
| 5.0 |  | ws1 | 🟡 pending | Update assignment show page | Display criterion averages and evaluation counts on assignment page | [Details 5.0](#task-5.0) |

## Implementation plan

### Task 1.0
Add points field to Level model through database migration and model updates.

### Task 2.0
Implement comprehensive validations for the points field to ensure data integrity.

### Task 3.0
Update the rubric and level creation process to automatically assign point values 0-4 to levels.

### Task 4.0
Add methods to calculate average performance levels per criterion across all student works.

### Task 5.0
Update the assignment show page to display criterion averages with evaluation counts.