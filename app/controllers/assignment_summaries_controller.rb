# frozen_string_literal: true

class AssignmentSummariesController < ApplicationController
  before_action :set_assignment_summary

  def show
    @assignment = @assignment_summary.assignment
  end

  private

  def set_assignment_summary
    @assignment_summary = AssignmentSummary.find(params[:id])
  end
end
