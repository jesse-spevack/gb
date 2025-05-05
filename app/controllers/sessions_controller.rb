class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
  end

  def create
    auth = request.env["omniauth.auth"]
    if auth
      user = Authorization::UserService.user_from_google_auth(auth)
      start_new_session_for(user)
      redirect_to assignments_path, notice: "Logged in."
    else
      redirect_to root_path, alert: "Login attempt failed, try again."
    end
  end

  def destroy
    Current.session.destroy
    cookies.delete(:session_id)
    redirect_to root_path, notice: "Logged out."
  end

  private

  def start_new_session_for(user)
    new_session = create_session_for(user)
    set_session_cookie(new_session)
    new_session
  end

  def create_session_for(user)
    user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )
  end

  def set_session_cookie(session)
    Current.session = session
    cookies.signed.permanent[:session_id] = {
      value: session.id,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end
end
