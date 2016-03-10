# == Schema Information
#
# Table name: fee_schedules
#
#  doctor_id   :integer          not null
#  id          :integer          not null, primary key
#  name        :string           default("Default"), not null
#  time_zone   :text             default("US/Pacific"), not null
#  weeks_ahead :integer          default(4), not null
#

class FeeSchedule < ActiveRecord::Base
  has_many :oncall_times
  has_many :fee_rules
  has_many :fee_rule_times
  belongs_to :doctor, inverse_of: :fee_schedules

  def fee_amount(start_time, tz, visit_type)
    visit_type_set = Set.new [:online, :office, :area]
    tz_offset = (start_time.in_time_zone(tz).utc_offset)/3600
    start_time_offset = (start_time.utc_offset)/3600
    unless visit_type_set.include? visit_type
      raise ArgumentError.new("visit_type value must equal :online, :office or :area, value given was: #{visit_type}")
    end
    unless tz_offset == start_time_offset
      raise ArgumentError.new("Mismatch between offset of start_time #{start_time_offset} and time zone argument #{tz_offset}")
    end


    frt = FeeRuleTime.
      where("fee_schedule_id = :fs_id and timestamptz :s_time <@ timerange",
            {fs_id: self.id, s_time: start_time.in_time_zone(tz)})
    if frt.count == 0
      raise RuntimeError.new("No fee_rule_time defined for for fee_schedule_id: #{self.id} at time: #{start_time.in_time_zone(tz)}")
    end

    case visit_type
    when :online
      return frt.take.online_visit_fee
    when :office
      return frt.take.office_visit_fee
    when :area
      return frt.take.area_visit_fee
    end
  end

end
