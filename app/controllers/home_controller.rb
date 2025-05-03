class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @git_commit = `git rev-parse --short HEAD`.chomp
  end
end
