# frozen_string_literal: true

class RubricsController < ApplicationController
  before_action :set_rubric

  def show
    @assignment = @rubric.assignment
  end

  private

  def set_rubric
    @rubric = Rubric.find(params[:id])
  end
end
