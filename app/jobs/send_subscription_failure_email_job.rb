class SendSubscriptionFailureEmailJob < ActiveJob::Base
  queue_as :default

  def perform(subscription)
    subscription.send_failure_email()
  end
end
