# frozen_string_literal: true

class Google::CredentialsController < ApplicationController
  def show
    credentials = Google::PickerService.call(Current.user)
    render json: {
      picker_token: credentials.picker_token,
      oauth_token: credentials.oauth_token,
      app_id: credentials.app_id
    }
  end
end
