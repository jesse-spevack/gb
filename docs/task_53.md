# Task 53: Pipeline Support Services Implementation Plan

## Overview
This implementation plan breaks down Task 53 into discrete, testable subtasks that can be executed independently by an AI coding partner. Each subtask follows TDD principles: write the test first, implement the code to make it pass, then refactor while keeping tests green.

**Goal**: Implement BroadcastService and RecordMetricsService to provide real-time UI updates via ActionCable and performance tracking for the pipeline architecture.

---

## Task Checklist

### Core Services
- [x] **Subtask 1**: ProcessingMetric Model Enhancement
- [x] **Subtask 2**: Assignment Progress Calculator Service
- [x] **Subtask 3**: Create View Partials for Progress Display
- [x] **Subtask 4**: BroadcastService Implementation
- [x] **Subtask 5**: RecordMetricsService Implementation

### View Integration
- [x] **Subtask 6**: Update Assignment Show View for Turbo Streams

### Pipeline Integration
- [x] **Subtask 7**: Update RubricPipeline with Support Services
- [x] **Subtask 8**: Update StudentWorkFeedbackPipeline with Support Services
- [x] **Subtask 9**: Update AssignmentSummaryPipeline with Support Services

### Testing & Validation
- [ ] **Subtask 10**: Integration Testing

---

## Subtask 1: ProcessingMetric Model Enhancement

### Prompt for Subtask 1

Create enhanced ProcessingMetric model with timing fields and proper indexes for performance tracking in the GradeBot pipeline architecture.

**Context:**
- GradeBot uses a pipeline architecture for processing assignments through AI
- ProcessingMetric tracks performance data for each pipeline execution
- We need to store timing information for overall pipeline execution and LLM calls
- The model already exists with basic fields but needs enhancement

**Requirements:**
- Create a migration to add timing fields to ProcessingMetrics
- Add indexes for efficient querying by assignment and user
- Update the ProcessingMetric model with any necessary validations or scopes

**Test First (TDD):**

Create `test/models/processing_metric_test.rb`:

```ruby
require "test_helper"

class ProcessingMetricTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:physics_assignment)
    @user = users(:teacher_user)
    @metric = ProcessingMetric.new(
      processable: @assignment,
      status: :completed,
      total_duration_ms: 5000,
      llm_duration_ms: 3000
    )
  end

  test "should be valid with required attributes" do
    assert @metric.valid?
  end

  test "should require total_duration_ms for completed status" do
    @metric.total_duration_ms = nil
    assert_not @metric.valid?
    assert_includes @metric.errors[:total_duration_ms], "can't be blank"
  end

  test "should not require duration fields for pending status" do
    @metric.status = :pending
    @metric.total_duration_ms = nil
    @metric.llm_duration_ms = nil
    assert @metric.valid?
  end

  test "should have scope for assignment metrics" do
    @metric.save!
    rubric = rubrics(:physics_rubric)
    ProcessingMetric.create!(
      processable: rubric,
      status: :completed,
      total_duration_ms: 1000,
      llm_duration_ms: 800
    )

    assignment_metrics = ProcessingMetric.for_assignment(@assignment)
    assert_equal 2, assignment_metrics.count # Assignment metric + rubric metric
  end

  test "should have scope for user metrics" do
    @metric.save!
    another_user = users(:another_teacher)
    another_assignment = assignments(:english_assignment)
    ProcessingMetric.create!(
      processable: another_assignment,
      status: :completed,
      total_duration_ms: 2000,
      llm_duration_ms: 1500
    )

    user_metrics = ProcessingMetric.for_user(@user)
    assert_equal 1, user_metrics.count
    assert_equal @metric, user_metrics.first
  end

  test "should calculate average durations" do
    3.times do |i|
      ProcessingMetric.create!(
        processable: @assignment,
        status: :completed,
        total_duration_ms: 1000 * (i + 1),
        llm_duration_ms: 500 * (i + 1)
      )
    end

    assert_equal 2000, ProcessingMetric.average_total_duration
    assert_equal 1000, ProcessingMetric.average_llm_duration
  end
end
```

**Implementation:**

Create migration `db/migrate/[timestamp]_add_timing_fields_to_processing_metrics.rb`:

```ruby
class AddTimingFieldsToProcessingMetrics < ActiveRecord::Migration[7.2]
  def change
    add_column :processing_metrics, :total_duration_ms, :integer
    add_column :processing_metrics, :llm_duration_ms, :integer
    add_column :processing_metrics, :metrics_data, :json, default: {}
    add_column :processing_metrics, :recorded_at, :datetime

    add_index :processing_metrics, [:processable_type, :processable_id], name: 'index_processing_metrics_on_processable'
    add_index :processing_metrics, :recorded_at
    
    # For finding all metrics related to an assignment (including its rubric, student works, etc)
    add_reference :processing_metrics, :assignment, foreign_key: true, index: true
    
    # For finding all metrics for a user's assignments
    add_reference :processing_metrics, :user, foreign_key: true, index: true
  end
end
```

Update `app/models/processing_metric.rb`:

```ruby
class ProcessingMetric < ApplicationRecord
  belongs_to :processable, polymorphic: true
  belongs_to :assignment, optional: true
  belongs_to :user, optional: true

  validates :processable, presence: true
  validates :status, presence: true
  validates :total_duration_ms, presence: true, if: :completed?
  
  before_save :set_associations

  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2
  }

  scope :for_assignment, ->(assignment) {
    where(assignment: assignment)
  }
  
  scope :for_user, ->(user) {
    where(user: user)
  }
  
  scope :completed, -> { where(status: :completed) }
  
  def self.average_total_duration
    completed.average(:total_duration_ms)&.to_i || 0
  end
  
  def self.average_llm_duration
    completed.average(:llm_duration_ms)&.to_i || 0
  end

  private

  def set_associations
    self.recorded_at ||= Time.current
    
    # Set assignment reference for easier querying
    case processable
    when Assignment
      self.assignment = processable
      self.user = processable.user
    when Rubric
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    when StudentWork
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    when AssignmentSummary
      self.assignment = processable.assignment
      self.user = processable.assignment.user
    end
  end
end
```

**Refactor:**
After tests pass, consider:
- Adding more specific scopes if needed
- Optimizing the set_associations method
- Adding database constraints in the migration

---

## Subtask 2: Assignment Progress Calculator Service

### Prompt for Subtask 2

Create Assignment::ProgressCalculator service that calculates completion progress based on LLM calls for the GradeBot pipeline.

**Context:**
- Assignments have three main processing phases: rubric generation (1 LLM call), student work feedback (N LLM calls, one per student work), and summary generation (1 LLM call)
- Progress should be calculated as a percentage of completed LLM calls vs total expected
- The calculator will be used by the BroadcastService to show real-time progress

**Requirements:**
- Calculate overall progress percentage based on completed LLM calls
- Track completion status for each phase (rubric, student works, summary)
- Return structured data for UI consumption

**Test First (TDD):**

Create `test/services/assignment/progress_calculator_test.rb`:

```ruby
require "test_helper"

module Assignment
  class ProgressCalculatorTest < ActiveSupport::TestCase
    def setup
      @assignment = assignments(:physics_assignment)
      @calculator = ProgressCalculator.new(@assignment)
    end

    test "calculates zero progress for new assignment" do
      # Assignment with no rubric, no feedback, no summary
      progress = @calculator.calculate
      
      assert_equal 0, progress[:overall_percentage]
      assert_equal 0, progress[:completed_llm_calls]
      assert_equal 32, progress[:total_llm_calls] # 1 rubric + 30 students + 1 summary
      assert_equal false, progress[:rubric_complete]
      assert_equal 0, progress[:student_works_complete]
      assert_equal false, progress[:summary_complete]
    end

    test "calculates progress with completed rubric" do
      # Create rubric with criteria to indicate completion
      rubric = rubrics(:physics_rubric)
      rubric.update!(assignment: @assignment)
      criteria(:physics_understanding).update!(rubric: rubric)
      
      progress = @calculator.calculate
      
      assert_equal 3, progress[:overall_percentage] # 1/32 ≈ 3%
      assert_equal 1, progress[:completed_llm_calls]
      assert_equal true, progress[:rubric_complete]
    end

    test "calculates progress with some student work completed" do
      # Complete 10 out of 30 student works
      10.times do |i|
        @assignment.student_works[i].update!(
          qualitative_feedback: "Great work on problem #{i + 1}!"
        )
      end
      
      progress = @calculator.calculate
      
      assert_equal 31, progress[:overall_percentage] # 10/32 ≈ 31%
      assert_equal 10, progress[:completed_llm_calls]
      assert_equal 10, progress[:student_works_complete]
      assert_equal 30, progress[:student_works_total]
    end

    test "calculates 100% when all phases complete" do
      # Complete rubric
      rubric = rubrics(:physics_rubric)
      rubric.update!(assignment: @assignment)
      criteria(:physics_understanding).update!(rubric: rubric)
      
      # Complete all student works
      @assignment.student_works.each do |work|
        work.update!(qualitative_feedback: "Feedback provided")
      end
      
      # Complete summary
      summary = assignment_summaries(:physics_summary)
      summary.update!(assignment: @assignment)
      
      progress = @calculator.calculate
      
      assert_equal 100, progress[:overall_percentage]
      assert_equal 32, progress[:completed_llm_calls] # 1 + 30 + 1
      assert_equal 32, progress[:total_llm_calls]
      assert_equal true, progress[:rubric_complete]
      assert_equal 30, progress[:student_works_complete]
      assert_equal true, progress[:summary_complete]
    end

    test "handles assignment with no student works" do
      @assignment.student_works.destroy_all
      
      progress = @calculator.calculate
      
      assert_equal 0, progress[:overall_percentage]
      assert_equal 2, progress[:total_llm_calls] # Just rubric + summary
      assert_equal 0, progress[:student_works_total]
    end

    test "includes detailed phase information" do
      progress = @calculator.calculate
      
      assert progress.key?(:phases)
      assert_equal :pending, progress[:phases][:rubric][:status]
      assert_equal :pending, progress[:phases][:student_works][:status]
      assert_equal :pending, progress[:phases][:summary][:status]
    end
  end
end
```

**Implementation:**

Create `app/services/assignment/progress_calculator.rb`:

```ruby
module Assignment
  class ProgressCalculator
    def initialize(assignment)
      @assignment = assignment
    end

    def calculate
      {
        overall_percentage: overall_percentage,
        completed_llm_calls: completed_llm_calls,
        total_llm_calls: total_llm_calls,
        rubric_complete: rubric_complete?,
        student_works_complete: completed_student_works_count,
        student_works_total: total_student_works_count,
        summary_complete: summary_complete?,
        phases: phase_details
      }
    end

    private

    def overall_percentage
      return 0 if total_llm_calls.zero?
      ((completed_llm_calls.to_f / total_llm_calls) * 100).round
    end

    def total_llm_calls
      # 1 for rubric + N for student works + 1 for summary
      1 + @assignment.student_works.count + 1
    end

    def completed_llm_calls
      count = 0
      count += 1 if rubric_complete?
      count += completed_student_works_count
      count += 1 if summary_complete?
      count
    end

    def rubric_complete?
      @assignment.rubric&.persisted? && @assignment.rubric.criteria.any?
    end

    def completed_student_works_count
      @assignment.student_works.where.not(qualitative_feedback: nil).count
    end

    def total_student_works_count
      @assignment.student_works.count
    end

    def summary_complete?
      @assignment.assignment_summary&.persisted?
    end

    def phase_details
      {
        rubric: {
          status: rubric_status,
          complete: rubric_complete?
        },
        student_works: {
          status: student_works_status,
          completed: completed_student_works_count,
          total: total_student_works_count,
          percentage: student_works_percentage
        },
        summary: {
          status: summary_status,
          complete: summary_complete?
        }
      }
    end

    def rubric_status
      return :completed if rubric_complete?
      return :in_progress if @assignment.processing_started_at.present?
      :pending
    end

    def student_works_status
      return :pending unless rubric_complete?
      return :completed if completed_student_works_count == total_student_works_count
      return :in_progress if completed_student_works_count > 0
      :pending
    end

    def summary_status
      return :completed if summary_complete?
      return :in_progress if completed_student_works_count == total_student_works_count
      :pending
    end

    def student_works_percentage
      return 0 if total_student_works_count.zero?
      ((completed_student_works_count.to_f / total_student_works_count) * 100).round
    end
  end
end
```

**Refactor:**
After tests pass:
- Consider caching calculations if called multiple times
- Add memoization for expensive queries
- Extract magic numbers into constants

---

## Subtask 3: Create View Partials for Progress Display

### Prompt for Subtask 3

Create Turbo-compatible view partials for displaying assignment processing progress in GradeBot's UI.

**Context:**
- GradeBot uses Turbo Streams to update the UI in real-time without page reloads
- We need partials that can be broadcast via ActionCable to show progress updates
- The UI should follow the existing style from home/index.html.erb and assignments/new.html.erb
- Each partial needs specific DOM IDs for Turbo Stream targeting

**Requirements:**
- Create progress_card partial showing overall assignment progress
- Create rubric_section partial for rubric display/status
- Create student_work_row partial for individual student work status
- All partials must have proper Turbo Stream target IDs

**Test First (TDD):**

Create `test/views/assignments/partials_test.rb`:

```ruby
require "test_helper"

class Assignments::PartialsTest < ActionView::TestCase
  include ActionView::Helpers::TagHelper
  
  def setup
    @assignment = assignments(:physics_assignment)
    @progress_metrics = Assignment::ProgressCalculator.new(@assignment).calculate
    @rubric = rubrics(:physics_rubric)
    @student_work = student_works(:physics_work_one)
  end

  test "progress_card renders with correct turbo stream target" do
    render partial: "assignments/progress_card", locals: { 
      assignment: @assignment, 
      progress_metrics: @progress_metrics 
    }
    
    assert_select "div#assignment_#{@assignment.id}_progress"
    assert_select "[data-turbo-permanent]"
    assert_select ".text-3xl", text: "0%"
    assert_select ".text-sm", text: /0 of \d+ steps complete/
  end

  test "progress_card shows phase statuses" do
    render partial: "assignments/progress_card", locals: { 
      assignment: @assignment, 
      progress_metrics: @progress_metrics 
    }
    
    assert_select ".phase-indicator", count: 3 # rubric, student works, summary
    assert_select ".phase-indicator.pending", count: 3
  end

  test "rubric_section renders pending state" do
    render partial: "assignments/rubric_section", locals: { 
      rubric: nil,
      assignment: @assignment 
    }
    
    assert_select "div#rubric_content"
    assert_select ".animate-spin" # Loading spinner
    assert_select "p", text: /Generating rubric/
  end

  test "rubric_section renders completed rubric" do
    @rubric.criteria.create!(
      title: "Understanding",
      description: "Student demonstrates understanding",
      position: 1
    )
    
    render partial: "assignments/rubric_section", locals: { 
      rubric: @rubric,
      assignment: @assignment 
    }
    
    assert_select "div#rubric_content"
    assert_select ".criterion", count: 1
    assert_select "h4", text: "Understanding"
  end

  test "student_work_row renders with turbo stream target" do
    render partial: "assignments/student_work_row", locals: { 
      work: @student_work,
      index: 0 
    }
    
    assert_select "div#student_work_#{@student_work.id}"
    assert_select ".student-work-title", text: @student_work.selected_document.title
  end

  test "student_work_row shows completion status" do
    @student_work.update!(qualitative_feedback: "Great work!")
    
    render partial: "assignments/student_work_row", locals: { 
      work: @student_work,
      index: 0 
    }
    
    assert_select ".status-badge.completed"
    assert_select ".status-badge", text: "Complete"
  end
end
```

**Implementation:**

Create `app/views/assignments/_progress_card.html.erb`:

```erb
<div id="assignment_<%= assignment.id %>_progress" 
     class="bg-white rounded-lg shadow-md p-6 transition-all hover:shadow-lg"
     data-turbo-permanent>
  
  <div class="flex items-center justify-between mb-6">
    <h3 class="text-lg font-semibold text-gray-900">Processing Progress</h3>
    <div class="text-3xl font-bold text-blue-600">
      <%= progress_metrics[:overall_percentage] %>%
    </div>
  </div>

  <div class="mb-4">
    <div class="flex justify-between text-sm text-gray-600 mb-2">
      <span><%= progress_metrics[:completed_llm_calls] %> of <%= progress_metrics[:total_llm_calls] %> steps complete</span>
      <span class="text-xs">
        <% if progress_metrics[:overall_percentage] < 100 %>
          Est. <%= pluralize(((progress_metrics[:total_llm_calls] - progress_metrics[:completed_llm_calls]) * 30), 'second') %> remaining
        <% end %>
      </span>
    </div>
    <div class="w-full bg-gray-200 rounded-full h-3">
      <div class="bg-gradient-to-r from-blue-500 to-blue-600 h-3 rounded-full transition-all duration-500 ease-out"
           style="width: <%= progress_metrics[:overall_percentage] %>%"></div>
    </div>
  </div>

  <div class="grid grid-cols-3 gap-4 mt-6">
    <!-- Rubric Phase -->
    <div class="text-center phase-indicator <%= progress_metrics[:phases][:rubric][:status] %>">
      <div class="mb-2">
        <% if progress_metrics[:phases][:rubric][:complete] %>
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto">
            <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
        <% elsif progress_metrics[:phases][:rubric][:status] == :in_progress %>
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto">
            <svg class="animate-spin h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
            </svg>
          </div>
        <% else %>
          <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto">
            <div class="w-3 h-3 bg-gray-400 rounded-full"></div>
          </div>
        <% end %>
      </div>
      <p class="text-xs font-medium text-gray-700">Rubric</p>
      <p class="text-xs text-gray-500 capitalize"><%= progress_metrics[:phases][:rubric][:status] %></p>
    </div>

    <!-- Student Works Phase -->
    <div class="text-center phase-indicator <%= progress_metrics[:phases][:student_works][:status] %>">
      <div class="mb-2">
        <% if progress_metrics[:phases][:student_works][:status] == :completed %>
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto">
            <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
        <% elsif progress_metrics[:phases][:student_works][:status] == :in_progress %>
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto relative">
            <span class="text-sm font-semibold text-blue-600">
              <%= progress_metrics[:phases][:student_works][:completed] %>/<%= progress_metrics[:phases][:student_works][:total] %>
            </span>
          </div>
        <% else %>
          <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto">
            <div class="w-3 h-3 bg-gray-400 rounded-full"></div>
          </div>
        <% end %>
      </div>
      <p class="text-xs font-medium text-gray-700">Student Work</p>
      <p class="text-xs text-gray-500">
        <%= progress_metrics[:phases][:student_works][:completed] %> of <%= progress_metrics[:phases][:student_works][:total] %>
      </p>
    </div>

    <!-- Summary Phase -->
    <div class="text-center phase-indicator <%= progress_metrics[:phases][:summary][:status] %>">
      <div class="mb-2">
        <% if progress_metrics[:phases][:summary][:complete] %>
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto">
            <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
        <% elsif progress_metrics[:phases][:summary][:status] == :in_progress %>
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto">
            <svg class="animate-spin h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
            </svg>
          </div>
        <% else %>
          <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto">
            <div class="w-3 h-3 bg-gray-400 rounded-full"></div>
          </div>
        <% end %>
      </div>
      <p class="text-xs font-medium text-gray-700">Summary</p>
      <p class="text-xs text-gray-500 capitalize"><%= progress_metrics[:phases][:summary][:status] %></p>
    </div>
  </div>
</div>
```

Create `app/views/assignments/_rubric_section.html.erb`:

```erb
<div id="rubric_content" class="bg-white rounded-lg shadow-md p-6">
  <% if rubric.nil? %>
    <!-- Pending State -->
    <div class="text-center py-12">
      <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
        <svg class="animate-spin h-8 w-8 text-blue-600" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
        </svg>
      </div>
      <p class="text-gray-600 font-medium">Generating rubric...</p>
      <p class="text-sm text-gray-500 mt-2">This typically takes 30-45 seconds</p>
    </div>
  <% else %>
    <!-- Completed State -->
    <div class="space-y-6">
      <% rubric.criteria.order(position: :asc).each do |criterion| %>
        <div class="criterion border-b border-gray-200 pb-6 last:border-0">
          <h4 class="text-lg font-semibold text-gray-900 mb-2"><%= criterion.title %></h4>
          <p class="text-gray-600 mb-4"><%= criterion.description %></p>
          
          <div class="grid grid-cols-1 md:grid-cols-<%= [criterion.levels.count, 4].min %> gap-3">
            <% criterion.levels.order(position: :asc).each do |level| %>
              <div class="bg-gradient-to-br from-gray-50 to-gray-100 p-4 rounded-lg border border-gray-200">
                <h5 class="font-medium text-gray-800 mb-1"><%= level.title %></h5>
                <p class="text-sm text-gray-600"><%= level.description %></p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>
</div>

<!-- Tab indicator update target -->
<span id="rubric_tab_indicator" class="ml-1">
  <% if rubric.present? %>
    <span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>
  <% end %>
</span>
```

Create `app/views/assignments/_student_work_row.html.erb`:

```erb
<div id="student_work_<%= work.id %>" 
     class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
  
  <div class="flex items-center justify-between">
    <div class="flex items-center flex-1">
      <div class="flex-shrink-0 w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center mr-4">
        <span class="text-sm font-semibold text-blue-600"><%= index + 1 %></span>
      </div>
      
      <div class="flex-1">
        <h4 class="student-work-title text-sm font-medium text-gray-900">
          <%= work.selected_document.title %>
        </h4>
        <div class="flex items-center mt-1">
          <% if work.qualitative_feedback.present? %>
            <svg class="w-4 h-4 text-green-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span class="text-xs text-green-600">Feedback complete</span>
          <% else %>
            <% if work.processing_started_at.present? %>
              <svg class="animate-spin h-4 w-4 text-blue-500 mr-1" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
              </svg>
              <span class="text-xs text-blue-600">Processing...</span>
            <% else %>
              <div class="w-3 h-3 bg-gray-300 rounded-full mr-2"></div>
              <span class="text-xs text-gray-500">Pending</span>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>

    <div class="flex items-center space-x-3">
      <% if work.qualitative_feedback.present? %>
        <span class="status-badge completed inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          Complete
        </span>
      <% elsif work.processing_started_at.present? %>
        <span class="status-badge processing inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
          Processing
        </span>
      <% else %>
        <span class="status-badge pending inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
          Pending
        </span>
      <% end %>
      
      <a href="<%= work.selected_document.url %>" 
         target="_blank" 
         rel="noopener noreferrer"
         class="inline-flex items-center text-sm text-blue-600 hover:text-blue-800 hover:bg-blue-50 px-3 py-1 rounded-md transition-colors">
        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
        </svg>
        View
      </a>
    </div>
  </div>
</div>
```

**Refactor:**
- Extract status badge rendering into a helper
- Consider using ViewComponent for reusable elements
- Add CSS classes for animation states

---

## Subtask 4: BroadcastService Implementation

### Prompt for Subtask 4

Implement BroadcastService that publishes real-time updates via Turbo Streams for the GradeBot pipeline.

**Context:**
- GradeBot uses a pipeline architecture where each step can broadcast status updates
- We use Turbo Streams (Rails 8 standard) instead of custom ActionCable channels
- The service needs to support configurable events (e.g., :rubric_started, :rubric_completed)
- View partials from Subtask 3 will be rendered and broadcast

**Requirements:**
- Create BroadcastService that integrates with Turbo::StreamsChannel
- Support configuration pattern: BroadcastService.with(event: :rubric_started)
- Broadcast appropriate HTML updates based on the processable type
- Update the correct DOM targets for each broadcast type

**Test First (TDD):**

Create `test/services/broadcast_service_test.rb`:

```ruby
require "test_helper"

class BroadcastServiceTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @assignment = assignments(:physics_assignment)
    @rubric = rubrics(:physics_rubric)
    @student_work = student_works(:physics_work_one)
  end

  test "broadcasts assignment progress update" do
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.status = :in_progress

    assert_broadcasts_on(@assignment, 1) do
      BroadcastService.call(context: context)
    end
  end

  test "configurable broadcast service sets status from event" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric

    service = BroadcastService.with(event: :rubric_completed)
    
    assert_broadcasts_on(@rubric.assignment, 2) do # Progress + rubric update
      result_context = service.call(context: context)
      assert_equal :completed, result_context.status
    end
  end

  test "broadcasts rubric updates to assignment stream" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    context.status = :completed

    assert_broadcasts_on(@rubric.assignment, 2) do
      BroadcastService.call(context: context)
    end
  end

  test "broadcasts student work updates" do
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.status = :in_progress

    assert_broadcasts_on(@student_work.assignment, 2) do # Progress + work update
      BroadcastService.call(context: context)
    end
  end

  test "returns context unchanged" do
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    original_metrics = context.metrics.dup

    result = BroadcastService.call(context: context)
    
    assert_equal context, result
    assert_equal original_metrics, result.metrics
  end

  test "handles assignment summary broadcasts" do
    summary = assignment_summaries(:physics_summary)
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment_summary = summary
    context.status = :completed

    assert_broadcasts_on(summary.assignment, 1) do
      BroadcastService.call(context: context)
    end
  end

  test "infers status when not explicitly set" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    context.parsed_response = { criteria: [] }

    assert_broadcasts_on(@rubric.assignment, 2) do
      BroadcastService.call(context: context)
    end
  end
end
```

**Implementation:**

Create `app/services/broadcast_service.rb`:

```ruby
class BroadcastService
  def self.call(context:)
    new(context).call
  end

  def self.with(event:)
    ConfiguredBroadcastService.new(event: event)
  end

  def initialize(context)
    @context = context
  end

  def call
    broadcast_updates
    @context
  end

  private

  def broadcast_updates
    case processable
    when Assignment
      broadcast_assignment_progress
    when Rubric
      broadcast_rubric_updates
    when StudentWork
      broadcast_student_work_updates
    when AssignmentSummary
      broadcast_summary_update
    end
  end

  def broadcast_assignment_progress
    progress_metrics = Assignment::ProgressCalculator.new(processable).calculate
    
    Turbo::StreamsChannel.broadcast_update_to(
      processable,
      target: "assignment_#{processable.id}_progress",
      partial: "assignments/progress_card",
      locals: { 
        assignment: processable,
        progress_metrics: progress_metrics
      }
    )
  end

  def broadcast_rubric_updates
    assignment = processable.assignment
    
    # Update rubric content
    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "rubric_content",
      partial: "assignments/rubric_section",
      locals: { 
        rubric: processable,
        assignment: assignment
      }
    )
    
    # Update tab indicator if completed
    if status == :completed
      Turbo::StreamsChannel.broadcast_update_to(
        assignment,
        target: "rubric_tab_indicator",
        html: '<span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>'
      )
    end
    
    # Also update overall progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_student_work_updates
    assignment = processable.assignment
    work_index = assignment.student_works.order(:id).pluck(:id).index(processable.id)
    
    # Update individual work row
    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "student_work_#{processable.id}",
      partial: "assignments/student_work_row",
      locals: { 
        work: processable,
        index: work_index || 0
      }
    )
    
    # Update overall progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_summary_update
    assignment = processable.assignment
    
    # Update summary tab indicator
    if status == :completed
      Turbo::StreamsChannel.broadcast_update_to(
        assignment,
        target: "summary_tab_indicator", 
        html: '<span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>'
      )
    end
    
    # Update progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_assignment_progress_for(assignment)
    progress_metrics = Assignment::ProgressCalculator.new(assignment).calculate
    
    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "assignment_#{assignment.id}_progress",
      partial: "assignments/progress_card",
      locals: { 
        assignment: assignment,
        progress_metrics: progress_metrics
      }
    )
  end

  def processable
    @context.assignment || 
    @context.rubric || 
    @context.student_work || 
    @context.assignment_summary
  end

  def status
    @context.status || infer_status
  end

  def infer_status
    if @context.errors.present?
      :failed
    elsif @context.parsed_response.present?
      :completed
    else
      :in_progress
    end
  end
end
```

Create `app/services/configured_broadcast_service.rb`:

```ruby
class ConfiguredBroadcastService
  def initialize(event:)
    @event = event
  end

  def call(context:)
    context.status = map_event_to_status(@event)
    BroadcastService.call(context: context)
  end

  private

  def map_event_to_status(event)
    case event
    when :rubric_started, :student_work_started, :summary_started
      :in_progress
    when :rubric_completed, :student_work_completed, :summary_completed  
      :completed
    when :rubric_failed, :student_work_failed, :summary_failed
      :failed
    else
      :pending
    end
  end
end
```

**Refactor:**
- Consider extracting broadcast target generation into a helper
- Add logging for debugging broadcast issues
- Consider batching multiple broadcasts together

---

## Subtask 5: RecordMetricsService Implementation

### Prompt for Subtask 5

Implement RecordMetricsService to capture and persist pipeline performance metrics for GradeBot.

**Context:**
- Processing metrics track the performance of each pipeline execution
- We need to record total duration and LLM-specific duration
- The ProcessingMetric model was enhanced in Subtask 1
- Metrics should be associated with the correct assignment and user for reporting

**Requirements:**
- Create RecordMetricsService that extracts timing from context
- Create ProcessingMetric records with proper associations
- Handle different processable types (Assignment, Rubric, StudentWork, AssignmentSummary)
- Service should be simple without defensive error handling

**Test First (TDD):**

Create `test/services/record_metrics_service_test.rb`:

```ruby
require "test_helper"

class RecordMetricsServiceTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:physics_assignment)
    @rubric = rubrics(:physics_rubric)
    @rubric.update!(assignment: @assignment)
  end

  test "records metrics for completed pipeline" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    context.add_metric(:llm_request_ms, 3500)
    context.add_metric(:tokens_used, 1200)
    
    # Simulate time passing
    context.instance_variable_set(:@started_at, 5.seconds.ago)

    assert_difference "ProcessingMetric.count", 1 do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal @rubric, metric.processable
    assert_equal :completed, metric.status.to_sym
    assert_equal @assignment, metric.assignment
    assert_equal @assignment.user, metric.user
    assert_in_delta 5000, metric.total_duration_ms, 100
    assert_equal 3500, metric.llm_duration_ms
  end

  test "records metrics for different processable types" do
    # Test with StudentWork
    student_work = student_works(:physics_work_one)
    context = Pipeline::Context::StudentWork.new
    context.student_work = student_work
    context.parsed_response = { feedback: "Great!" }
    context.add_metric(:llm_request_ms, 2000)

    assert_difference "ProcessingMetric.count", 1 do
      RecordMetricsService.call(context: context)
    end

    metric = ProcessingMetric.last
    assert_equal student_work, metric.processable
    assert_equal :completed, metric.status.to_sym
    assert_equal student_work.assignment, metric.assignment
  end

  test "determines failed status from context errors" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    context.errors = ["LLM request failed"]

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal :failed, metric.status.to_sym
  end

  test "returns context unchanged" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric
    original_metrics = { test: "value" }
    context.instance_variable_set(:@metrics, original_metrics)

    result = RecordMetricsService.call(context: context)
    
    assert_equal context, result
    assert_equal original_metrics, result.metrics
  end

  test "stores pipeline type in metrics data" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal "rubric_generation", metric.metrics_data["pipeline_type"]
  end

  test "handles assignment summary metrics" do
    summary = assignment_summaries(:physics_summary)
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment_summary = summary
    context.add_metric(:llm_request_ms, 4000)

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal summary, metric.processable
    assert_equal summary.assignment, metric.assignment
    assert_equal "summary_generation", metric.metrics_data["pipeline_type"]
  end

  test "records zero duration for instant operations" do
    context = Pipeline::Context::Rubric.new
    context.rubric = @rubric

    RecordMetricsService.call(context: context)

    metric = ProcessingMetric.last
    assert_equal 0, metric.total_duration_ms
  end
end
```

**Implementation:**

Create `app/services/record_metrics_service.rb`:

```ruby
class RecordMetricsService
  def self.call(context:)
    new(context).call
  end

  def initialize(context)
    @context = context
  end

  def call
    ProcessingMetric.create!(
      processable: processable,
      status: determine_status,
      total_duration_ms: @context.total_duration_ms,
      llm_duration_ms: @context.metrics[:llm_request_ms],
      metrics_data: build_metrics_data
    )
    
    @context
  end

  private

  def processable
    @context.assignment || 
    @context.rubric || 
    @context.student_work || 
    @context.assignment_summary
  end

  def determine_status
    if @context.errors.present?
      :failed
    elsif @context.parsed_response.present?
      :completed  
    else
      :pending
    end
  end

  def build_metrics_data
    {
      pipeline_type: pipeline_type,
      timestamp: Time.current,
      tokens_used: @context.metrics[:tokens_used],
      raw_metrics: @context.metrics
    }.compact
  end

  def pipeline_type
    case processable
    when Rubric then "rubric_generation"
    when StudentWork then "student_feedback"
    when AssignmentSummary then "summary_generation"  
    when Assignment then "assignment_processing"
    else "unknown"
    end
  end
end
```

**Refactor:**
- Consider adding more detailed metrics to metrics_data
- Add scopes to ProcessingMetric for common queries
- Consider async metric recording for performance

---

## Subtask 6: Update Assignment Show View for Turbo Streams

### Prompt for Subtask 6

Update the assignment show view to integrate Turbo Stream subscriptions for real-time updates in GradeBot.

**Context:**
- The current show view displays assignment details but doesn't update in real-time
- We need to add Turbo Stream subscriptions to receive broadcasts
- The view should use the partials created in Subtask 3
- Each updateable section needs proper DOM IDs for targeting

**Requirements:**
- Add Turbo Stream subscription tags
- Replace static content with partials that can be updated
- Ensure all sections have proper IDs for Turbo targeting
- Maintain existing functionality while adding real-time capabilities

**Test First (TDD):**

Create `test/controllers/assignments_controller_test.rb` (add to existing file):

```ruby
class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:teacher_user)
    @assignment = assignments(:physics_assignment)
    sign_in_as(@user)
  end

  test "show includes turbo stream subscriptions" do
    get assignment_path(@assignment)
    
    assert_response :success
    
    # Check for Turbo Stream subscription
    assert_select "turbo-cable-stream-source[channel='Turbo::StreamsChannel']"
    
    # Check for properly targeted elements
    assert_select "#assignment_#{@assignment.id}_progress"
    assert_select "#rubric_content"
    assert_select "#rubric_tab_indicator"
    assert_select "#summary_tab_indicator"
  end

  test "show renders student work rows with IDs" do
    get assignment_path(@assignment)
    
    @assignment.student_works.each do |work|
      assert_select "#student_work_#{work.id}"
    end
  end

  test "show uses progress calculator" do
    Assignment::ProgressCalculator.any_instance.expects(:calculate).returns({
      overall_percentage: 50,
      completed_llm_calls: 15,
      total_llm_calls: 30,
      phases: {}
    })

    get assignment_path(@assignment)
    assert_response :success
  end

  test "show renders with no rubric" do
    @assignment.rubric&.destroy
    
    get assignment_path(@assignment)
    
    assert_response :success
    assert_select "#rubric_content"
  end

  private

  def sign_in_as(user)
    # Your authentication test helper
    session[:user_id] = user.id
  end
end
```

**Implementation:**

Update `app/views/assignments/show.html.erb`:

```erb
<%= turbo_stream_from @assignment %>

<div class="bg-gray-50 min-h-screen">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header -->
    <div class="mb-6">
      <div class="flex items-center">
        <%= link_to assignments_path, class: "mr-4 p-2 rounded-full hover:bg-gray-100 transition-colors" do %>
          <%= render "shared/icons/arrow_left", class: "w-5 h-5 text-gray-600" %>
        <% end %>
        <div>
          <h1 class="text-2xl font-bold text-gray-900"><%= @assignment.title %></h1>
          <p class="text-sm text-gray-600 mt-1">
            <%= @assignment.subject %> • <%= @assignment.grade_level %>
          </p>
        </div>
      </div>
    </div>

    <!-- Progress Card -->
    <%= render "assignments/progress_card", 
               assignment: @assignment, 
               progress_metrics: @progress_metrics %>

    <!-- Navigation Tabs -->
    <div class="mb-6">
      <nav class="flex space-x-1 bg-white rounded-lg shadow-sm p-1" aria-label="Assignment sections">
        <%= link_to assignment_path(@assignment, section: 'details'), 
                    class: tab_classes('details', @active_section),
                    data: { turbo_frame: "_top" } do %>
          <%= render "shared/icons/clipboard_document", class: "h-4 w-4 mr-1.5 inline-block" %>
          Details
        <% end %>
        
        <%= link_to assignment_path(@assignment, section: 'rubric'), 
                    class: tab_classes('rubric', @active_section),
                    data: { turbo_frame: "_top" } do %>
          <%= render "shared/icons/clipboard_list", class: "h-4 w-4 mr-1.5 inline-block" %>
          Rubric
          <span id="rubric_tab_indicator">
            <% if @assignment.rubric&.persisted? %>
              <span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>
            <% end %>
          </span>
        <% end %>
        
        <%= link_to assignment_path(@assignment, section: 'student_works'), 
                    class: tab_classes('student_works', @active_section),
                    data: { turbo_frame: "_top" } do %>
          <%= render "shared/icons/document", class: "h-4 w-4 mr-1.5 inline-block" %>
          Student Work
          <span class="ml-1 bg-gray-200 text-gray-700 text-xs px-2 py-0.5 rounded-full">
            <%= @assignment.student_works.count %>
          </span>
        <% end %>
        
        <%= link_to assignment_path(@assignment, section: 'summary'), 
                    class: tab_classes('summary', @active_section),
                    data: { turbo_frame: "_top" } do %>
          <%= render "shared/icons/chart_bar", class: "h-4 w-4 mr-1.5 inline-block" %>
          Summary
          <span id="summary_tab_indicator">
            <% if @assignment.assignment_summary&.persisted? %>
              <span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>
            <% end %>
          </span>
        <% end %>
      </nav>
    </div>

    <!-- Content Sections -->
    <div class="content-sections">
      <% case @active_section %>
      <% when 'details' %>
        <div class="bg-white rounded-lg shadow-md p-6">
          <div class="flex items-center mb-4">
            <%= render "shared/icons/clipboard_document", class: "h-5 w-5 mr-2 text-blue-500" %>
            <h3 class="font-medium text-gray-900">Assignment Details</h3>
          </div>

          <div class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 class="text-sm font-medium text-gray-700 mb-1">Subject</h4>
                <p class="text-base text-gray-900"><%= @assignment.subject.presence || "Not specified" %></p>
              </div>
              <div>
                <h4 class="text-sm font-medium text-gray-700 mb-1">Grade Level</h4>
                <p class="text-base text-gray-900"><%= @assignment.grade_level.presence || "Not specified" %></p>
              </div>
            </div>

            <div>
              <h4 class="text-sm font-medium text-gray-700 mb-1">Instructions</h4>
              <div class="p-4 bg-gray-50 rounded-md">
                <%= simple_format(@assignment.instructions, class: "text-gray-900") %>
              </div>
            </div>

            <div>
              <h4 class="text-sm font-medium text-gray-700 mb-1">Feedback Tone</h4>
              <p class="text-base text-gray-900 capitalize"><%= @assignment.feedback_tone %></p>
            </div>
          </div>
        </div>

      <% when 'rubric' %>
        <%= render "assignments/rubric_section", 
                   rubric: @assignment.rubric,
                   assignment: @assignment %>

      <% when 'student_works' %>
        <div class="bg-white rounded-lg shadow-md p-6">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center">
              <%= render "shared/icons/document", class: "h-5 w-5 mr-2 text-blue-500" %>
              <h3 class="font-medium text-gray-900">Student Work</h3>
            </div>
            <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded">
              <%= pluralize(@assignment.student_works.count, 'document') %>
            </span>
          </div>

          <% if @assignment.student_works.any? %>
            <div class="space-y-3">
              <% @assignment.student_works.order(:id).each_with_index do |work, index| %>
                <%= render "assignments/student_work_row", 
                           work: work,
                           index: index %>
              <% end %>
            </div>
          <% else %>
            <div class="text-center py-8">
              <div class="text-gray-400 mb-4">
                <%= render "shared/icons/document", class: "h-12 w-12 mx-auto" %>
              </div>
              <p class="text-gray-500 italic">No student work has been added to this assignment.</p>
            </div>
          <% end %>
        </div>

      <% when 'summary' %>
        <div id="summary_content" class="bg-white rounded-lg shadow-md p-6">
          <% if @assignment.assignment_summary.present? %>
            <%= render "assignments/summary_section", 
                       summary: @assignment.assignment_summary %>
          <% else %>
            <div class="text-center py-12">
              <div class="text-gray-400 mb-4">
                <%= render "shared/icons/chart_bar", class: "h-12 w-12 mx-auto" %>
              </div>
              <p class="text-gray-500 italic">Assignment summary is not yet available.</p>
              <p class="text-sm text-gray-400 mt-2">
                The summary will be generated after all student work has been processed.
              </p>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>

    <!-- Action Buttons -->
    <div class="mt-8 flex justify-end">
      <%= button_to assignment_path(@assignment), 
                    method: :delete,
                    form: { 
                      data: { 
                        turbo_confirm: "Are you sure you want to delete this assignment? This action cannot be undone.",
                        turbo_frame: "_top"
                      }
                    },
                    class: "inline-flex items-center px-4 py-2 border border-red-300 shadow-sm text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50 transition-colors" do %>
        <%= render "shared/icons/trash", class: "h-4 w-4 mr-2" %>
        Delete Assignment
      <% end %>
    </div>
  </div>
</div>
```

Update `app/controllers/assignments_controller.rb` (add to show action):

```ruby
def show
  @assignment = current_user.assignments.find(params[:id])
  @active_section = params[:section] || 'details'
  @progress_metrics = Assignment::ProgressCalculator.new(@assignment).calculate
  
  respond_to do |format|
    format.html
    format.turbo_stream
  end
end

private

def tab_classes(tab, active_tab)
  base_classes = "flex-1 text-center py-2 px-4 rounded-md text-sm font-medium transition-all"
  if tab == active_tab
    "#{base_classes} bg-blue-100 text-blue-700"
  else
    "#{base_classes} text-gray-500 hover:text-gray-700 hover:bg-gray-50"
  end
end
```

Add helper method to `app/helpers/assignments_helper.rb`:

```ruby
module AssignmentsHelper
  def tab_classes(tab, active_tab)
    base_classes = "flex-1 text-center py-2 px-4 rounded-md text-sm font-medium transition-all inline-flex items-center justify-center"
    if tab == active_tab
      "#{base_classes} bg-blue-100 text-blue-700"
    else
      "#{base_classes} text-gray-500 hover:text-gray-700 hover:bg-gray-50"
    end
  end
end
```

**Refactor:**
- Extract tab navigation into a partial
- Consider using ViewComponent for complex UI elements
- Add loading states for better UX

---

## Subtask 7: Update RubricPipeline with Support Services

### Prompt for Subtask 7

Integrate BroadcastService and RecordMetricsService into the RubricPipeline for real-time updates and metrics tracking.

**Context:**
- RubricPipeline processes assignment rubric generation through LLM
- BroadcastService was implemented in Subtask 4
- RecordMetricsService was implemented in Subtask 5
- Pipeline steps are configured as a constant array

**Requirements:**
- Add broadcast steps at start and completion of rubric generation
- Add metrics recording at the end of the pipeline
- Ensure proper event configuration for broadcasts
- Maintain existing pipeline functionality

**Test First (TDD):**

Create `test/pipelines/rubric_pipeline_test.rb`:

```ruby
require "test_helper"

class RubricPipelineTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @assignment = assignments(:physics_assignment)
    @user = users(:teacher_user)
  end

  test "pipeline includes broadcast steps" do
    expected_steps = [
      PromptInput::Rubric,
      BroadcastService.with(event: :rubric_started),
      LLM::Rubric::Generator,
      LLM::Rubric::ResponseParser,
      Pipeline::Storage::RubricService,
      BroadcastService.with(event: :rubric_completed),
      RecordMetricsService
    ]

    assert_equal expected_steps, RubricPipeline::STEPS
  end
end
```
**Implementation:**

Update `app/pipelines/rubric_pipeline.rb`:

```ruby
class RubricPipeline < Pipeline::Base
  STEPS = [
    PromptInput::Rubric,
    BroadcastService.with(event: :rubric_started),
    LLM::Rubric::Generator,
    LLM::Rubric::ResponseParser,
    Pipeline::Storage::RubricService,
    BroadcastService.with(event: :rubric_completed),
    RecordMetricsService
  ].freeze

  private

  def self.execute_pipeline(context)
    STEPS.each do |step|
      context = step.call(context: context)
    end
  end

  def self.create_context(assignment:, user:)
    context = Pipeline::Context::Rubric.new
    context.assignment = assignment
    context.user = user
    context
  end

  def self.extract_result_data(context)
    context.saved_rubric
  end
end
```

Ensure `Pipeline::Base` exists with this structure:

```ruby
module Pipeline
  class Base
    def self.call(**args)
      context = create_context(**args)
      
      begin
        execute_pipeline(context)
        build_success_result(context)
      rescue => e
        build_failure_result(context, e)
      end
    end

    private

    def self.execute_pipeline(context)
      raise NotImplementedError
    end

    def self.create_context(**args)
      raise NotImplementedError
    end

    def self.build_success_result(context)
      ProcessingResult.new(
        success: true,
        data: extract_result_data(context),
        errors: [],
        metrics: context.metrics
      )
    end

    def self.build_failure_result(context, error)
      ProcessingResult.new(
        success: false,
        data: nil,
        errors: [error.message],
        metrics: context&.metrics || {}
      )
    end

    def self.extract_result_data(context)
      nil
    end
  end
end
```

**Refactor:**
- Consider adding more granular broadcast events
- Add timing measurements between steps
- Consider making broadcast events configurable

---

## Subtask 8: Update StudentWorkFeedbackPipeline with Support Services

### Prompt for Subtask 8

Integrate BroadcastService and RecordMetricsService into the StudentWorkFeedbackPipeline for real-time updates and metrics tracking.

**Context:**
- StudentWorkFeedbackPipeline processes individual student work through LLM
- This pipeline runs once for each student work in an assignment
- Broadcasting updates helps show progress as each work is completed
- Similar pattern to RubricPipeline but for student work

**Requirements:**
- Add broadcast steps at start and completion of student work processing
- Add metrics recording at the end of the pipeline
- Ensure broadcasts update both individual work and overall progress
- Maintain existing pipeline functionality

**Test First (TDD):**

Create `test/pipelines/student_work_feedback_pipeline_test.rb`:

```ruby
require "test_helper"

class StudentWorkFeedbackPipelineTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @assignment = assignments(:physics_assignment)
    @rubric = rubrics(:physics_rubric)
    @rubric.update!(assignment: @assignment)
    @student_work = student_works(:physics_work_one)
    @user = users(:teacher_user)
  end

  test "pipeline includes broadcast and metrics steps" do
    pipeline_steps = StudentWorkFeedbackPipeline::STEPS
    
    # Verify broadcast steps
    assert pipeline_steps.any? { |s| 
      s.is_a?(ConfiguredBroadcastService) && 
      s.instance_variable_get(:@event) == :student_work_started 
    }
    assert pipeline_steps.any? { |s| 
      s.is_a?(ConfiguredBroadcastService) && 
      s.instance_variable_get(:@event) == :student_work_completed 
    }
    
    # Verify metrics step
    assert pipeline_steps.include?(RecordMetricsService)
  end

  test "pipeline broadcasts updates during execution" do
    stub_pipeline_steps

    # Should broadcast: start update + progress, complete update + progress (4 total)
    assert_broadcasts_on(@assignment, 4) do
      StudentWorkFeedbackPipeline.call(
        student_work: @student_work,
        rubric: @rubric,
        user: @user
      )
    end
  end

  test "pipeline records metrics for student work" do
    stub_pipeline_steps

    assert_difference "ProcessingMetric.count", 1 do
      result = StudentWorkFeedbackPipeline.call(
        student_work: @student_work,
        rubric: @rubric,
        user: @user
      )
      
      assert result.successful?
    end

    metric = ProcessingMetric.last
    assert_equal @student_work, metric.processable
    assert_equal @assignment, metric.assignment
    assert_equal @user, metric.user
    assert_equal :completed, metric.status.to_sym
    assert_equal "student_feedback", metric.metrics_data["pipeline_type"]
    assert_equal 3000, metric.llm_duration_ms
  end

  test "broadcasts include work-specific targets" do
    stub_pipeline_steps
    
    # Expect broadcasts to specific student work target
    Turbo::StreamsChannel.expects(:broadcast_update_to).with(
      @assignment,
      target: "student_work_#{@student_work.id}",
      partial: "assignments/student_work_row",
      locals: { work: @student_work, index: anything }
    ).at_least_once

    StudentWorkFeedbackPipeline.call(
      student_work: @student_work,
      rubric: @rubric,
      user: @user
    )
  end

  test "pipeline continues on broadcast failure" do
    stub_pipeline_steps
    Turbo::StreamsChannel.stubs(:broadcast_update_to).raises(StandardError)

    result = StudentWorkFeedbackPipeline.call(
      student_work: @student_work,
      rubric: @rubric,
      user: @user
    )

    assert result.successful?
    assert @student_work.reload.qualitative_feedback.present?
  end

  private

  def stub_pipeline_steps
    PromptInput::StudentWork.stubs(:build_and_attach_to_context).returns(
      ->(context:) { 
        context.prompt = "Analyze student work"
        context 
      }
    )
    
    LLM::StudentWork::Generator.stubs(:call).returns(
      ->(context:) {
        context.llm_response = OpenStruct.new(
          content: '{"feedback": "Great work!"}',
          total_tokens: 150
        )
        context.add_metric(:llm_request_ms, 3000)
        context.add_metric(:tokens_used, 150)
        context
      }
    )
    
    LLM::StudentWork::ResponseParser.stubs(:call).returns(
      ->(context:) {
        context.parsed_response = { 
          qualitative_feedback: "Great work!",
          feedback_items: []
        }
        context
      }
    )
    
    Pipeline::Storage::StudentWorkService.stubs(:persist_to_database).returns(
      ->(context:) {
        @student_work.update!(qualitative_feedback: "Great work!")
        context.saved_feedback = @student_work
        context
      }
    )
  end
end
```

**Implementation:**

Update or create `app/pipelines/student_work_feedback_pipeline.rb`:

```ruby
class StudentWorkFeedbackPipeline < Pipeline::Base
  STEPS = [
    PromptInput::StudentWork,
    BroadcastService.with(event: :student_work_started),
    LLM::StudentWork::Generator,
    LLM::StudentWork::ResponseParser,
    Pipeline::Storage::StudentWorkService,
    BroadcastService.with(event: :student_work_completed),
    RecordMetricsService
  ].freeze

  private

  def self.execute_pipeline(context)
    STEPS.each do |step|
      context = step.call(context: context)
    end
  end

  def self.create_context(student_work:, rubric:, user:)
    context = Pipeline::Context::StudentWork.new
    context.student_work = student_work
    context.rubric = rubric
    context.user = user
    context.assignment = student_work.assignment
    context
  end

  def self.extract_result_data(context)
    context.saved_feedback
  end
end
```

Ensure the context includes assignment reference:

```ruby
module Pipeline
  module Context
    class StudentWork < Base
      attr_accessor :student_work, :rubric, :assignment, :saved_feedback
      
      def initialize
        super
      end
    end
  end
end
```

**Refactor:**
- Consider batching broadcasts for multiple student works
- Add progress percentage to student work broadcasts
- Consider adding retry logic for failed student works

---

## Subtask 9: Update AssignmentSummaryPipeline with Support Services

### Prompt for Subtask 9

Integrate BroadcastService and RecordMetricsService into the AssignmentSummaryPipeline for real-time updates and metrics tracking.

**Context:**
- AssignmentSummaryPipeline generates class-wide insights after all student work is complete
- This is the final step in assignment processing
- Broadcasting the summary completion shows 100% progress
- Similar pattern to other pipelines

**Requirements:**
- Add broadcast steps at start and completion of summary generation
- Add metrics recording at the end of the pipeline
- Ensure summary completion triggers final progress update
- Update summary tab indicator when complete

**Test First (TDD):**

Create `test/pipelines/assignment_summary_pipeline_test.rb`:

```ruby
require "test_helper"

class AssignmentSummaryPipelineTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @assignment = assignments(:physics_assignment)
    @user = users(:teacher_user)
    
    # Setup completed student works
    @student_feedbacks = @assignment.student_works.map do |work|
      work.update!(qualitative_feedback: "Feedback provided")
      { 
        student_work: work,
        feedback: "Feedback provided",
        strengths: ["Good understanding"],
        areas_for_improvement: ["Show more work"]
      }
    end
  end

  test "pipeline includes broadcast and metrics steps" do
    pipeline_steps = AssignmentSummaryPipeline::STEPS
    
    assert pipeline_steps.any? { |s| 
      s.is_a?(ConfiguredBroadcastService) && 
      s.instance_variable_get(:@event) == :summary_started 
    }
    assert pipeline_steps.any? { |s| 
      s.is_a?(ConfiguredBroadcastService) && 
      s.instance_variable_get(:@event) == :summary_completed 
    }
    assert pipeline_steps.include?(RecordMetricsService)
  end

  test "pipeline broadcasts summary updates" do
    stub_pipeline_steps

    # Should broadcast progress updates and tab indicator update
    assert_broadcasts_on(@assignment, 2) do
      AssignmentSummaryPipeline.call(
        assignment: @assignment,
        student_feedbacks: @student_feedbacks,
        user: @user
      )
    end
  end

  test "pipeline records metrics for summary generation" do
    stub_pipeline_steps

    assert_difference "ProcessingMetric.count", 1 do
      result = AssignmentSummaryPipeline.call(
        assignment: @assignment,
        student_feedbacks: @student_feedbacks,
        user: @user
      )
      
      assert result.successful?
    end

    metric = ProcessingMetric.last
    assert_equal @assignment.assignment_summary, metric.processable
    assert_equal @assignment, metric.assignment
    assert_equal @user, metric.user
    assert_equal :completed, metric.status.to_sym
    assert_equal "summary_generation", metric.metrics_data["pipeline_type"]
  end

  test "summary completion shows 100% progress" do
    stub_pipeline_steps
    
    # Ensure rubric exists
    rubric = rubrics(:physics_rubric)
    rubric.update!(assignment: @assignment)
    criteria(:physics_understanding).update!(rubric: rubric)

    # Mock progress calculator to verify 100%
    Assignment::ProgressCalculator.any_instance.expects(:calculate).returns({
      overall_percentage: 100,
      completed_llm_calls: 32,
      total_llm_calls: 32,
      summary_complete: true,
      phases: {}
    }).at_least_once

    AssignmentSummaryPipeline.call(
      assignment: @assignment,
      student_feedbacks: @student_feedbacks,
      user: @user
    )
  end

  test "broadcasts update summary tab indicator" do
    stub_pipeline_steps

    Turbo::StreamsChannel.expects(:broadcast_update_to).with(
      @assignment,
      target: "summary_tab_indicator",
      html: '<span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>'
    ).once

    AssignmentSummaryPipeline.call(
      assignment: @assignment,
      student_feedbacks: @student_feedbacks,
      user: @user
    )
  end

  private

  def stub_pipeline_steps
    PromptInput::AssignmentSummary.stubs(:build_and_attach_to_context).returns(
      ->(context:) { 
        context.prompt = "Generate summary"
        context 
      }
    )
    
    LLM::AssignmentSummary::Generator.stubs(:call).returns(
      ->(context:) {
        context.llm_response = OpenStruct.new(
          content: '{"insights": "Class performed well"}',
          total_tokens: 200
        )
        context.add_metric(:llm_request_ms, 4000)
        context
      }
    )
    
    LLM::AssignmentSummary::ResponseParser.stubs(:call).returns(
      ->(context:) {
        context.parsed_response = { 
          qualitative_insights: "Class performed well overall",
          feedback_items: []
        }
        context
      }
    )
    
    Pipeline::Storage::AssignmentSummaryService.stubs(:persist_to_database).returns(
      ->(context:) {
        summary = AssignmentSummary.create!(
          assignment: @assignment,
          qualitative_insights: "Class performed well",
          student_work_count: @student_feedbacks.count
        )
        context.saved_summary = summary
        context
      }
    )
  end
end
```

**Implementation:**

Create `app/pipelines/assignment_summary_pipeline.rb`:

```ruby
class AssignmentSummaryPipeline < Pipeline::Base
  STEPS = [
    PromptInput::AssignmentSummary,
    BroadcastService.with(event: :summary_started),
    LLM::AssignmentSummary::Generator,
    LLM::AssignmentSummary::ResponseParser,
    Pipeline::Storage::AssignmentSummaryService,
    BroadcastService.with(event: :summary_completed),
    RecordMetricsService
  ].freeze

  private

  def self.execute_pipeline(context)
    STEPS.each do |step|
      context = step.call(context: context)
    end
  end

  def self.create_context(assignment:, student_feedbacks:, user:)
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = assignment
    context.student_feedbacks = student_feedbacks
    context.user = user
    context
  end

  def self.extract_result_data(context)
    context.saved_summary
  end
end
```

Ensure context is properly defined:

```ruby
module Pipeline
  module Context
    class AssignmentSummary < Base
      attr_accessor :assignment, :student_feedbacks, :assignment_summary, :saved_summary
      
      def initialize
        super
      end
    end
  end
end
```

Create summary section partial `app/views/assignments/_summary_section.html.erb`:

```erb
<div class="space-y-6">
  <div class="bg-purple-50 p-4 rounded-lg">
    <h4 class="text-sm font-semibold text-purple-900 mb-2">Class Overview</h4>
    <p class="text-sm text-purple-800">
      Analysis based on <%= pluralize(summary.student_work_count, 'student submission') %>
    </p>
  </div>

  <div>
    <h4 class="text-sm font-semibold text-gray-900 mb-3">Key Insights</h4>
    <div class="prose prose-sm max-w-none text-gray-700">
      <%= simple_format(summary.qualitative_insights) %>
    </div>
  </div>

  <% if summary.feedback_items.any? %>
    <div>
      <h4 class="text-sm font-semibold text-gray-900 mb-3">Class Patterns</h4>
      <div class="space-y-3">
        <% summary.feedback_items.group_by(&:item_type).each do |type, items| %>
          <div>
            <h5 class="text-xs font-medium uppercase tracking-wide text-gray-600 mb-2">
              <%= type == 'strength' ? 'Strengths' : 'Areas for Improvement' %>
            </h5>
            <div class="space-y-2">
              <% items.each do |item| %>
                <div class="border-l-4 <%= type == 'strength' ? 'border-green-400 bg-green-50' : 'border-amber-400 bg-amber-50' %> p-3">
                  <p class="font-medium text-sm text-gray-900"><%= item.title %></p>
                  <p class="text-sm text-gray-700 mt-1"><%= item.description %></p>
                  <% if item.evidence.present? %>
                    <p class="text-xs text-gray-500 mt-2 italic">
                      <%= item.evidence %>
                    </p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

**Refactor:**
- Consider caching summary results
- Add visualization components for insights
- Consider email notification on completion

---

## Subtask 10: Integration Testing

### Prompt for Subtask 10

Create comprehensive integration tests to verify the complete pipeline flow with broadcasting and metrics recording.

**Context:**
- All pipeline components have been implemented
- We need to verify the complete flow from assignment processing through broadcasts
- Tests should cover the happy path and edge cases
- Focus on ensuring all services work together correctly

**Requirements:**
- Test complete assignment processing flow
- Verify broadcasts are sent at correct times
- Confirm metrics are recorded for all pipelines
- Test error scenarios and recovery

**Test First (TDD):**

Create `test/integration/assignment_processing_integration_test.rb`:

```ruby
require "test_helper"

class AssignmentProcessingIntegrationTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  def setup
    @user = users(:teacher_user)
    @assignment = assignments(:physics_assignment)
    sign_in_as(@user)
    
    # Stub LLM calls for consistent testing
    stub_llm_responses
  end

  test "complete assignment processing with real-time updates" do
    # Track metrics creation
    assert_difference "ProcessingMetric.count", 33 do # 1 rubric + 30 works + 1 summary + 1 overall
      # Track broadcasts (multiple per pipeline step)
      assert_broadcasts_on(@assignment, 66) do # 2 per pipeline * 33 pipelines
        AssignmentProcessor.new(@assignment).process
      end
    end

    # Verify final state
    @assignment.reload
    assert @assignment.rubric.present?
    assert_equal 30, @assignment.student_works.where.not(qualitative_feedback: nil).count
    assert @assignment.assignment_summary.present?

    # Verify metrics
    metrics = ProcessingMetric.for_assignment(@assignment)
    assert_equal 32, metrics.count
    assert metrics.all?(&:completed?)
    
    # Check metric types
    assert_equal 1, metrics.where(processable_type: "Rubric").count
    assert_equal 30, metrics.where(processable_type: "StudentWork").count
    assert_equal 1, metrics.where(processable_type: "AssignmentSummary").count
  end

  test "viewing assignment shows real-time progress" do
    get assignment_path(@assignment)
    assert_response :success
    
    # Verify initial state
    assert_select "#assignment_#{@assignment.id}_progress"
    assert_select ".text-3xl", text: "0%"
    
    # Start processing in background
    perform_enqueued_jobs do
      AssignmentJob.perform_later(@assignment)
    end
    
    # Verify completion
    get assignment_path(@assignment)
    assert_select ".text-3xl", text: "100%"
    assert_select "#rubric_content .criterion", count: 2 # Assuming 2 criteria
    assert_select ".status-badge.completed", count: 30
  end

  test "broadcast failures don't stop processing" do
    # Force broadcast failures
    Turbo::StreamsChannel.stubs(:broadcast_update_to).raises(StandardError).then.returns(true)
    
    assert_nothing_raised do
      AssignmentProcessor.new(@assignment).process
    end
    
    # Verify processing completed despite broadcast errors
    assert @assignment.reload.rubric.present?
    assert @assignment.assignment_summary.present?
  end

  test "progress calculator accuracy throughout processing" do
    calculator = Assignment::ProgressCalculator.new(@assignment)
    
    # Initial state
    progress = calculator.calculate
    assert_equal 0, progress[:overall_percentage]
    assert_equal 32, progress[:total_llm_calls]
    
    # After rubric
    create_rubric_for(@assignment)
    progress = calculator.calculate
    assert_equal 3, progress[:overall_percentage] # 1/32
    
    # After half student works
    15.times do |i|
      @assignment.student_works[i].update!(qualitative_feedback: "Feedback")
    end
    progress = calculator.calculate
    assert_equal 50, progress[:overall_percentage] # 16/32
    
    # After all student works
    @assignment.student_works.update_all(qualitative_feedback: "Feedback")
    progress = calculator.calculate
    assert_equal 97, progress[:overall_percentage] # 31/32
    
    # After summary
    create_summary_for(@assignment)
    progress = calculator.calculate
    assert_equal 100, progress[:overall_percentage]
  end

  test "concurrent pipeline execution tracking" do
    # Simulate concurrent student work processing
    threads = []
    
    5.times do |i|
      threads << Thread.new do
        work = @assignment.student_works[i]
        StudentWorkFeedbackPipeline.call(
          student_work: work,
          rubric: create_rubric_for(@assignment),
          user: @user
        )
      end
    end
    
    threads.each(&:join)
    
    # Verify all metrics recorded
    metrics = ProcessingMetric.where(
      processable_type: "StudentWork",
      processable_id: @assignment.student_works.limit(5).pluck(:id)
    )
    
    assert_equal 5, metrics.count
    assert metrics.all? { |m| m.total_duration_ms.positive? }
  end

  private

  def sign_in_as(user)
    post sessions_path, params: { 
      provider: :google_oauth2,
      uid: user.uid 
    }
  end

  def stub_llm_responses
    # Stub all LLM generators to return consistent responses
    LLM::Rubric::Generator.stubs(:call).returns(
      ->(context:) {
        context.llm_response = OpenStruct.new(
          content: rubric_response_json,
          total_tokens: 100
        )
        context.add_metric(:llm_request_ms, 1000)
        context
      }
    )
    
    LLM::StudentWork::Generator.stubs(:call).returns(
      ->(context:) {
        context.llm_response = OpenStruct.new(
          content: student_feedback_json,
          total_tokens: 150
        )
        context.add_metric(:llm_request_ms, 1500)
        context
      }
    )
    
    LLM::AssignmentSummary::Generator.stubs(:call).returns(
      ->(context:) {
        context.llm_response = OpenStruct.new(
          content: summary_response_json,
          total_tokens: 200
        )
        context.add_metric(:llm_request_ms, 2000)
        context
      }
    )
  end

  def rubric_response_json
    {
      criteria: [
        {
          title: "Understanding",
          description: "Demonstrates understanding of concepts",
          levels: [
            { title: "Excellent", description: "Complete understanding" },
            { title: "Good", description: "Solid understanding" },
            { title: "Developing", description: "Partial understanding" }
          ]
        }
      ]
    }.to_json
  end

  def student_feedback_json
    {
      qualitative_feedback: "Good work overall. Shows understanding of key concepts.",
      feedback_items: [
        {
          type: "strength",
          title: "Clear explanations",
          description: "Student explains their reasoning well"
        }
      ]
    }.to_json
  end

  def summary_response_json
    {
      qualitative_insights: "Class shows strong understanding overall with room for improvement in problem-solving approaches.",
      feedback_items: [
        {
          type: "strength",
          title: "Conceptual understanding",
          description: "Most students grasp the core concepts"
        }
      ]
    }.to_json
  end

  def create_rubric_for(assignment)
    rubric = Rubric.create!(assignment: assignment)
    Criterion.create!(
      rubric: rubric,
      title: "Understanding",
      description: "Shows understanding",
      position: 1
    )
    rubric
  end

  def create_summary_for(assignment)
    AssignmentSummary.create!(
      assignment: assignment,
      qualitative_insights: "Class performed well",
      student_work_count: assignment.student_works.count
    )
  end
end
```

**Implementation:**

This is primarily a test file, but we need to ensure `AssignmentProcessor` exists:

```ruby
# app/services/assignment_processor.rb
class AssignmentProcessor
  def initialize(assignment)
    @assignment = assignment
    @user = assignment.user
  end

  def process
    # Process rubric
    rubric_result = RubricPipeline.call(
      assignment: @assignment,
      user: @user
    )
    
    return aggregate_results([rubric_result]) unless rubric_result.successful?
    
    # Process each student work
    feedback_results = @assignment.student_works.map do |student_work|
      StudentWorkFeedbackPipeline.call(
        student_work: student_work,
        rubric: rubric_result.data,
        user: @user
      )
    end
    
    # Process summary
    summary_result = AssignmentSummaryPipeline.call(
      assignment: @assignment,
      student_feedbacks: feedback_results.select(&:successful?).map(&:data),
      user: @user
    )
    
    # Record overall metrics
    record_overall_metrics(rubric_result, feedback_results, summary_result)
    
    aggregate_results([rubric_result] + feedback_results + [summary_result])
  end

  private

  def aggregate_results(results)
    Pipeline::ProcessingResults.new(results)
  end

  def record_overall_metrics(rubric_result, feedback_results, summary_result)
    all_results = [rubric_result] + feedback_results + [summary_result]
    
    ProcessingMetric.create!(
      processable: @assignment,
      status: all_results.all?(&:successful?) ? :completed : :failed,
      total_duration_ms: all_results.sum { |r| r.timing_ms },
      llm_duration_ms: all_results.sum { |r| r.llm_timing_ms },
      metrics_data: {
        pipeline_type: "assignment_processing",
        rubric_success: rubric_result.successful?,
        student_works_processed: feedback_results.count,
        student_works_successful: feedback_results.count(&:successful?),
        summary_success: summary_result.successful?
      }
    )
  end
end
```

**Refactor:**
- Add performance benchmarking
- Consider adding system tests with Capybara
- Add monitoring and alerting for production

---

## Summary

This implementation plan provides a complete, testable approach to adding real-time broadcasting and metrics tracking to the GradeBot pipeline architecture. Each subtask can be implemented independently while building toward the complete solution.

Key benefits:
- **Real-time feedback**: Users see progress updates as processing happens
- **Performance visibility**: Metrics tracking enables optimization
- **Maintainable architecture**: Clear separation of concerns with focused services
- **Robust error handling**: Processing continues even if auxiliary services fail

The TDD approach ensures each component is thoroughly tested before integration, reducing bugs and improving code quality.# Task 53: Pipeline Support Services Implementation Plan
