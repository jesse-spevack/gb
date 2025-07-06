# frozen_string_literal: true

class StudentWorksController < ApplicationController
  before_action :set_student_work
  before_action :authorize_student_work

  def show
    @assignment = @student_work.assignment
  end

  private

  def set_student_work
    @student_work = StudentWork.find(params[:id])
  end

  def authorize_student_work
    redirect_to assignments_path, alert: "Student work is not available." unless @student_work.assignment.user_id == Current.user.id
  end
end
