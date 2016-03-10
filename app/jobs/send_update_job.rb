class SendUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(email)
    email.send_update
  end
end
