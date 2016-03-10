class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_username(params[:email])
    SendPasswordResetJob.perform_later(user) if user

    redirect_to root_url, notice: "If your account exists, an email was sent with password reset instructions."
  end

  def edit 
    @user = User.find_by_password_reset_token!(params[:id])
  end

  def update
    @user = User.find_by_password_reset_token!(params[:id])
    if @user.password_reset_sent_at < 2.hours.ago
      redirect_to new_password_reset_path, alert: "Sorry, the password reset has expired!"
    elsif @user.update_attributes(params[:user].permit(:password, :password_confirmation))
      redirect_to root_url, notice: "The password has been reset!"
    else
      render :edit
    end
  end
end
