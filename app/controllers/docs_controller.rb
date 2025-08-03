class DocsController < ApplicationController
  def show
    case params[:id]
    when "check-results"
      render "check_results"
    else
      raise ActionController::RoutingError.new("Not Found")
    end
  end
end
