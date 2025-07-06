# frozen_string_literal: true

class AssignmentSummariesController < ApplicationController
  before_action :set_assignment_summary
  before_action :authorize_assignment_summary
  def show
    @assignment = @assignment_summary.assignment
  end

  private

  def set_assignment_summary
    @assignment_summary = AssignmentSummary.find(params[:id])
  end

  def authorize_assignment_summary
    redirect_to assignments_path, alert: "Assignment summary is not available." unless @assignment_summary.assignment.user_id == Current.user.id
  end
end
