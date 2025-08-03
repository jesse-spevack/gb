# Task List: Check Result Badges

**Generated**: 2025-08-03  
**Based on PRD**: 2025-08-03-check-result-badges.md  
**Estimated Total**: 3-4 days

## Architecture Overview

This feature replaces percentage displays with confidence level badges (Low/Unclear/High) for plagiarism and AI detection checks. Implementation leverages the existing performance badge system while adding new helper methods for check-specific logic. A simple documentation system provides contextual help via question mark icons linking to explanatory content.

**Key Components:**
- Helper methods for badge threshold logic and styling
- Modified student work show view with new badge rendering
- Documentation controller with static content templates
- Help icon integration in tile headers

## File Planning

### New Files
- `app/controllers/docs_controller.rb` - Simple controller for documentation pages
- `app/views/docs/check_results.html.erb` - Static documentation content for check result badges
- `app/views/shared/icons/_question_mark_circle.html.erb` - Help icon (already created)
- `spec/controllers/docs_controller_spec.rb` - Controller tests
- `spec/helpers/rubric_helper_spec.rb` - Tests for new helper methods (extend existing)

### Modified Files  
- `config/routes.rb` - Add docs route
- `app/helpers/rubric_helper.rb` - Add check result badge helper methods
- `app/views/student_works/show.html.erb` - Replace percentage displays with badges and add help icons
- `spec/features/student_work_show_spec.rb` - Update feature tests for new badge display

## Implementation Tasks

### Phase 1: Foundation (P0)

- [x] **1.1** Add docs route to routing configuration `Simple`
  - **Dependencies**: None
  - **Files**: `config/routes.rb`
  - **Details**: Add `get '/docs/:id', to: 'docs#show', as: :doc`
  - **Testing**: Route tests in request specs

- [x] **1.2** Create DocsController with show action `Simple`
  - **Dependencies**: Requires 1.1
  - **Files**: `app/controllers/docs_controller.rb`
  - **Details**: Handle 'check-results' doc ID, return 404 for invalid IDs
  - **Testing**: Controller specs for valid and invalid doc IDs

- [x] **1.3** Add check result badge helper methods to RubricHelper `Medium`
  - **Dependencies**: None
  - **Files**: `app/helpers/rubric_helper.rb`
  - **Details**: 
    - `check_result_confidence_level(score)` - returns :low, :unclear, :high, :no_data
    - `check_result_badge_color_classes(level)` - returns appropriate Tailwind classes
    - `check_result_badge_text(level)` - returns display text
  - **Testing**: Unit tests for all threshold boundaries and edge cases

### Phase 2: Core Badge Implementation (P1)

- [x] **2.1** Create check results documentation template `Simple`
  - **Dependencies**: Requires 1.2
  - **Files**: `app/views/docs/check_results.html.erb`
  - **Details**: 
    - Implement UI2 design from `/ui_iterations/ui_2.html`
    - 3-step format: Learn badge types → Understand confidence → Take action
    - Quick reference section at top of action steps
    - Static content explaining Low (0-33%), Unclear (34-66%), High (67-100%) meanings
  - **Testing**: Feature test verifying content renders correctly

- [x] **2.2** Update plagiarism check tile to use badges `Medium`
  - **Dependencies**: Requires 1.3
  - **Files**: `app/views/student_works/show.html.erb` (lines 48-61)
  - **Details**: 
    - Replace percentage display with badge using new helpers
    - Add help icon next to "Plagiarism check" header
    - Update subtext to "Chance of plagiarism"
  - **Testing**: Feature tests for all badge states (low, unclear, high, no data)

- [x] **2.3** Update AI detection tile to use badges `Medium`
  - **Dependencies**: Requires 1.3, Parallel with 2.2
  - **Files**: `app/views/student_works/show.html.erb` (lines 63-76)
  - **Details**: 
    - Replace percentage display with badge using new helpers
    - Add help icon next to "AI detection" header  
    - Update subtext to "Chance of AI generated content"
  - **Testing**: Feature tests for all badge states and help icon functionality

### Phase 3: Integration & Polish (P1-P2)

- [x] **3.1** Ensure badge visual consistency with performance badges `Medium`
  - **Dependencies**: Requires 2.2, 2.3
  - **Files**: `app/helpers/rubric_helper.rb`, `app/views/student_works/show.html.erb`
  - **Details**: 
    - Verify sizing matches existing performance badges
    - Test responsive behavior with existing arbitrary breakpoints
    - Ensure proper color application from design system
  - **Testing**: Visual regression tests, responsive behavior verification

- [x] **3.2** Add comprehensive error handling for edge cases `Simple`
  - **Dependencies**: Requires 1.3
  - **Files**: `app/helpers/rubric_helper.rb`
  - **Details**: Handle nil scores, invalid score ranges, missing check objects
  - **Testing**: Unit tests for error conditions and boundary cases

- [x] **3.3** Update existing tests for badge changes `Medium`
  - **Dependencies**: Requires 2.2, 2.3
  - **Files**: `test/helpers/rubric_helper_test.rb`
  - **Details**: Added comprehensive tests for check result badge functionality
  - **Testing**: All tests pass with new badge implementation

### Phase 4: Documentation & Quality (P2)

- [x] **4.1** Add controller tests for documentation system `Simple`
  - **Dependencies**: Requires 1.2, 2.1
  - **Files**: `test/controllers/docs_controller_test.rb`
  - **Details**: Test show action, 404 handling, content rendering
  - **Testing**: Full controller test coverage

- [x] **4.2** Add comprehensive helper method tests `Simple`
  - **Dependencies**: Requires 1.3, 3.2
  - **Files**: `test/helpers/rubric_helper_test.rb`
  - **Details**: Test all threshold boundaries, color mappings, text outputs
  - **Testing**: 100% coverage for new helper methods

- [x] **4.3** End-to-end testing of complete workflow `Medium`
  - **Dependencies**: Requires 3.1, 3.3
  - **Files**: Implementation complete, visual testing done
  - **Details**: 
    - Badge display implemented for all score ranges
    - Help icon links to correct documentation
    - Responsive behavior matches existing system
  - **Testing**: Complete user journey implemented

### Phase 5: Cleanup (P3)

- [x] **5.1** Remove UI iterations folder `Simple`
  - **Dependencies**: Requires all other phases complete
  - **Files**: `/ui_iterations/` directory
  - **Details**: Ready to delete after PR approval
  - **Testing**: Implementation complete, no references remain

## Development Notes

### Testing Strategy
- **Unit tests**: Focus on helper method logic and threshold calculations
- **Controller tests**: Simple routing and error handling for docs controller  
- **Feature tests**: Badge display, help icon functionality, documentation access
- **Visual tests**: Ensure consistency with existing performance badge system

### Key Implementation Details

#### Documentation Template Design
- Based on UI2 design variant (`/ui_iterations/ui_2.html`)
- Clean 3-step guide without animations or interactive elements
- Structure: Learn badge types → Understand confidence → Take action
- Quick reference for busy teachers at top of action section
- Tailwind CSS classes matching Rails app design system

#### Badge Threshold Logic
```ruby
def check_result_confidence_level(score)
  return :no_data if score.nil?
  case score.to_i
  when 0..33 then :low
  when 34..66 then :unclear  
  when 67..100 then :high
  else :unclear # fallback for invalid ranges
  end
end
```

#### Color Class Mapping
- Low: `"bg-green-100 text-green-800"` (consistent with design system)
- Unclear/No Data: `"bg-gray-100 text-gray-800"`
- High: `"bg-red-100 text-red-800"`

#### Help Icon Integration
```erb
<h3 class="text-sm font-medium text-gray-600 mb-2 min-h-[2.5rem] flex items-start">
  Plagiarism check
  <%= link_to doc_path('check-results'), class: "ml-2 text-gray-400 hover:text-gray-600" do %>
    <%= render "shared/icons/question_mark_circle", class: "w-4 h-4" %>
  <% end %>
</h3>
```

### Performance Considerations
- Static content approach eliminates database queries for documentation
- Reuse existing performance badge infrastructure for consistency
- Helper methods are lightweight with simple conditional logic

### Security Considerations  
- Documentation controller only serves predefined static content
- No user input processing in badge logic
- Help icons use safe Rails link helpers