# frozen_string_literal: true

class StudentWorksController < ApplicationController
  before_action :set_student_work

  def show
    @assignment = @student_work.assignment
  end

  private

  def set_student_work
    @student_work = StudentWork.find(params[:id])
  end
end
