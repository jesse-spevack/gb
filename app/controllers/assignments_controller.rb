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
    @student_works = @assignment.student_works
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
