class SendSignupEmailsJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    user.send_signup_emails
  end
end
