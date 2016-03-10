# == Schema Information
#
# Table name: fee_rules
#
#  id                   :integer          not null, primary key
#  day_of_week          :integer          not null
#  fee                  :decimal(4, )     not null
#  duration             :string           default("00:30:00"), not null
#  fee_schedule_id      :integer          not null
#  time_of_day_range    :timerange        not null
#  online_visit_allowed :text             default("not_allowed"), not null
#  office_visit_allowed :text             default("not_allowed"), not null
#  area_visit_allowed   :text             default("not_allowed"), not null
#  online_visit_fee     :decimal(4, )     default(100), not null
#  office_visit_fee     :decimal(4, )     default(100), not null
#  area_visit_fee       :decimal(4, )     default(100), not null
#

class FeeRule < ActiveRecord::Base
  belongs_to :fee_schedule

  before_save do
    if self.time_of_day_range.end.strftime('%H:%M') == '00:00'
      # tz = self.fee_schedule.timezone
      self.time_of_day_range = (self.time_of_day_range.
          begin. # .in_time_zone(tz)).
          strftime('%H:%M'))...('23:59')
    end
  end
end
