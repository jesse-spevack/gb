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

    # Calculate progress metrics using the ProgressCalculator service
    @progress_metrics = Assignments::ProgressCalculator.new(@assignment).calculate

    # Check if processing is currently active
    @processing_active = !Assignments::CompletionChecker.call(@assignment) && @assignment.created_at > 1.hour.ago

    # Calculate criterion averages if assignment is complete
    @criterion_averages = Assignments::Statistics.get_criterion_performance(@assignment) if Assignments::CompletionChecker.call(@assignment)

    # Determine active section from params, default to 'details'
    @active_section = params[:section]&.in?(%w[details rubric student_works summary]) ? params[:section] : "details"

    respond_to do |format|
      format.html # Default HTML response
      format.json do
        render json: {
          progress_metrics: @progress_metrics,
          processing_active: @processing_active,
          rubric_complete: @rubric.present?,
          summary_complete: @assignment_summary.present?
        }
      end
    end
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
end
