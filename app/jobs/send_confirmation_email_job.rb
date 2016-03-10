class SendConfirmationEmailJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    user.send_confirmation_email
  end
end
