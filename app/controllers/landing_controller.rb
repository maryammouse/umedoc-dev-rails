class LandingController < ApplicationController
  def index
  end

  def mailing

    email = MailingList.new(email: mail_params[:email], campaign: 'House Calls')
    if email.save
      SendUpdateJob.perform_later(email) if email
      flash[:success] = "You are now part of the mailing list! Thanks for joining. We'll keep the emails to a minimum but we will let you
know when the house calls are up and running! You should recieve an email to confirm this."
    else
      email.errors.full_messages.each do |msg|
        flash[:warning] = msg
        flash[:warning] << "<br> Please try again."
        redirect_to('/house_calls') and return
      end
    end

    redirect_to('/house_calls')
  end

  def thanks
  end

  private

    def mail_params
      params.permit(:email)
    end

end
