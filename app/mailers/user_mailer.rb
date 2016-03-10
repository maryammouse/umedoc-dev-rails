class UserMailer < ApplicationMailer
  default from: "maryam@umedoc.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    @user = user
    mail to: user.username, subject: "Umedoc Password Reset"
  end

  def signup_thanks_user(user)
    @user = user
    mail to: user.username, subject: "Welcome to Umedoc, #{user.firstname}! Please confirm this email address."
  end

  def signup_notification_user(user)
    @user = user
    recipients = ["maryam@umedoc.com", "shamoun@umedoc.com", "ghufran@umedoc.com"]
    mail to: recipients, subject: "Bleep Bloop, New Patient Alert: #{user.firstname} #{user.lastname}"
  end

  def signup_thanks_doctor(user)
    @user = user
    mail to: user.username, subject: "Welcome to Umedoc, Dr. #{user.lastname}! Please confirm this email address."
  end

  def signup_notification_doctor(user)
    @user = user
    recipients = ["maryam@umedoc.com", "shamoun@umedoc.com", "ghufran@umedoc.com"]
    mail to: recipients, subject: "Bleep Bloop, New Doctor Alert: Dr. #{user.firstname} #{user.lastname}"
  end

  def confirmation_email(user)
    @user = user
    mail to: user.username, subject: "Confirm your email address with Umedoc"
  end

end
