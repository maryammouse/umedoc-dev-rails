class SendSubscriptionConfirmationJob < ActiveJob::Base
  queue_as :default

  def perform(subscription)
    subscription.send_confirmation
  end
end