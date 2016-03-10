class TestNotificationJob < ActiveJob::Base
  include TwilioSms

  queue_as :default

  def perform(full_cell_number, message )
    send_sms(full_cell_number,
             "This is a test message: #{message}")
  end
end
