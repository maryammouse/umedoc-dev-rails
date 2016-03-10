module SubscriptionHelper
  def handle_success_invoice(event_object)
    subscription = Subscription.find_by(subscription_id: event_object["lines"]["data"][0]["id"])
    subscription.update_column(:status, "active")

    SendSubscriptionConfirmationJob.perform_later(subscription)
  end

  def handle_failure_invoice(event_object)
    subscription = Subscription.find_by(subscription_id: event_object["lines"]["data"][0]["id"])
    subscription.update_column(:status, "canceled")

    SendSubscriptionFailureEmailJob.perform_later(subscription)
  end

  def handle_deleted_subscription(event_object)
    subscription = Subscription.find_by(subscription_id: event_object["id"])
    old_data = ArchivedSubscription.new(subscription_id: subscription.id, stripe_data: event_object,
    stripe_seller_id: subscription.plan.stripe_seller.id)
    old_data.save
  end

  def handle_subscription_update(event_object)
    subscription = Subscription.find_by(subscription_id: event_object["id"])
    subscription.update_column(:status, event_object["status"])
  end

  #TODO: Some will already have paid for months, some just in that month
  # TODO: make sure we update based on which they do


end
