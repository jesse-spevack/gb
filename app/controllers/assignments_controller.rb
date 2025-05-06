class AssignmentsController < ApplicationController
  def index
  end

  def new
    @assignment = Current.user.assignments.new
  end
end
