class Subscription < ActiveRecord::Base
  before_save :stripe_subscription

  belongs_to :stripe_customer
  belongs_to :plan

  def stripe_subscription
    begin
      customer_token = Stripe::Token.create(
          { customer: stripe_customer.customer_id },
          plan.stripe_seller.access_token
      )

      doctor_customer = Stripe::Customer.create(
          {
              :source => customer_token,
              :description => stripe_customer.user.username
          }, plan.stripe_seller.access_token
      )

      sub = doctor_customer.subscriptions.create({:plan => plan.plan_id , application_fee_percent: 0.1},
                                           plan.stripe_seller.access_token)

      self.subscription_id = sub.id
      self.status = sub.status

    rescue => e
      errors.add(:subscription_id, e.message)
      return false
    end
  end

  def send_confirmation
    SubscriptionMailer.confirmation(self).deliver_now
  end

  def send_failure_email
    SubscriptionMailer.failure_mailer(self).deliver_now
  end
end
