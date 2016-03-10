class SendPasswordResetJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    user.send_password_reset
  end
end
