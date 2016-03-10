class SubscriptionMailer < ApplicationMailer
  default from: "maryam@umedoc.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.subscription_mailer.confirmation.subject
  #
  def confirmation(subscription)
     @subscription = subscription
     mail to: @subscription.stripe_customer.user.username, subject: "Regarding your Umedoc You subscription"
  end

  def failure_mailer(subscription)
    @subscription = subscription
    mail to: @subscription.stripe_customer.user.username, subject: "Your Umedoc You subscription payment failed!"
  end
end
