class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(username: params[:session][:username])
    if user && user.authenticate(params[:session][:password])
      log_in(user)
      flash[:success] = "You have logged in! Nice one."
      redirect_to '/visits'
    else
      flash.now[:danger] = "Oops! That's an invalid email/password combination!"
      render 'new'
    end
  end

  def code
  end

  def verify
    user = User.find_by(id: session[:user_id])
    verification = params[:verification]
    answer = Authy::API.verify(:id => user.authy_id, :token => verification[:token], :force => true)

    if answer.ok?
      unless session[:current_visit_id].nil?
        current_visit = Visit.find(session[:current_visit_id])
        current_visit.authenticated = '1'
        current_visit.save(validate: false)
        session[:current_visit_id] = nil
      end
      redirect_to session[:redirect_to] and (session[:redirect_to] = nil and return)
    else
      flash[:warning] = "The code was invalid. Please re-enter it or request a new one."
      render 'code'
    end
  end

  def resend
    response_sms = Authy::API.request_sms(:id => current_user.authy_id)
    flash[:info] = "Your code has been resent!"
    redirect_to('/verify')
  end

  def destroy
    log_out
    flash[:success] = "You have successfully logged out. See you again soon!"
    redirect_to root_url
  end


end
