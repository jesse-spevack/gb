class AssignmentsController < ApplicationController
  before_action :set_assignment, only: [ :show, :destroy ]
  before_action :authorize_assignment, only: [ :show, :destroy ]

  def index
    @assignments = Current.user.assignments
  end

  def new
    @assignment = Current.user.assignments.new
  end

  def create
    result = Assignments::CreationService.create(assignment_input)
    if result.success?
      redirect_to assignment_path(result.assignment)
    else
      flash.now[:alert] = result.error_message
      @assignment = Current.user.assignments.new
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Load associated records efficiently to avoid N+1 queries
    @student_works = @assignment.student_works.includes(:selected_document, :feedback_items)
    @rubric = @assignment.rubric
    @assignment_summary = @assignment.assignment_summary

    # Calculate progress metrics
    @progress_metrics = calculate_progress_metrics

    # Calculate criterion averages if rubric exists
    @criterion_averages = Assignments::Statistics.new(@assignment).criterion_performance if @rubric.present?

    # Determine active section from params, default to 'details'
    @active_section = params[:section]&.in?(%w[details rubric student_works summary]) ? params[:section] : "details"
  end

  def destroy
    @assignment.destroy
    redirect_to assignments_path, notice: "Assignment deleted."
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def authorize_assignment
    redirect_to assignments_path, alert: "Assignment is not available." unless @assignment.user_id == Current.user.id
  end

  def assignment_params
    params.expect(assignment: [ :id, :title, :subject, :grade_level, :instructions, :raw_rubric_text, :feedback_tone, :document_data ])
  end

  def assignment_input
    AssignmentInput.new(
      assignment_params: assignment_params,
      user: Current.user
    )
  end

  # Calculate progress metrics for the assignment
  def calculate_progress_metrics
    total_student_works = @student_works.count
    return { total: 0, completed: 0, percentage: 0 } if total_student_works == 0

    # Count student works with feedback
    completed_student_works = @student_works.select { |sw| sw.qualitative_feedback.present? }.count

    percentage = total_student_works > 0 ? (completed_student_works.to_f / total_student_works * 100).round : 0

    {
      total: total_student_works,
      completed: completed_student_works,
      percentage: percentage,
      rubric_generated: @rubric.present?,
      summary_generated: @assignment_summary.present?
    }
  end
end
