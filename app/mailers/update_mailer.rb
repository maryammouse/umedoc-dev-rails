class UpdateMailer < ApplicationMailer
  default from: "maryam@umedoc.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def confirm_update(mailing_email)
    @email = mailing_email
    mail to: mailing_email.email, subject: "Coming Soon: " + @email.campaign
  end
end
