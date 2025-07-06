# frozen_string_literal: true

class RubricsController < ApplicationController
  before_action :set_rubric
  before_action :authorize_rubric

  def show
    @assignment = @rubric.assignment
  end

  private

  def set_rubric
    @rubric = Rubric.find(params[:id])
  end

  def authorize_rubric
    redirect_to assignments_path, alert: "Rubric is not available." unless @rubric.assignment.user_id == Current.user.id
  end
end
