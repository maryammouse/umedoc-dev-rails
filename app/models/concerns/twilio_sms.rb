module TwilioSms
    extend ActiveSupport::Concern

      $TWILIO_ACCOUNT_SID =   ENV['TWILIO_ACCOUNT_SID']
      $TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN']
      $TWILIO_CLIENT = Twilio::REST::Client.new($TWILIO_ACCOUNT_SID, $TWILIO_AUTH_TOKEN)
      $TWILIO_NUMBER = ENV['TWILIO_NUMBER']


    def send_sms(to, body)
      message = $TWILIO_CLIENT.account.messages.create(
        to: to,
        from: $TWILIO_NUMBER,
        body: body)
    end
    

    def visit_notifications()

      time_zone = oncall_time.fee_schedule.time_zone
      sms_1_time = timerange.begin.in_time_zone(time_zone) - 30.minutes
      sms_2_time = timerange.begin.in_time_zone(time_zone) - 15.minutes
      sms_3_time = timerange.begin.in_time_zone(time_zone) - 5.minutes

      VisitNotificationJob.set(wait_until: sms_1_time).
            perform_later(self)
      VisitNotificationJob.set(wait_until: sms_2_time).
            perform_later(self)
      VisitNotificationJob.set(wait_until: sms_3_time).
            perform_later(self)
    end
end
