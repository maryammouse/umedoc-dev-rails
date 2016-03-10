module OverlapValidator
  extend ActiveSupport::Concern
  def valid_oncall_timerange?(doctor_id, timerange)
    @start_time = timerange.begin
    @end_time = timerange.end

    if OncallTime.where(doctor_id:doctor_id).
      where("timerange && tstzrange(:start_time, :end_time)",
                     {start_time:@start_time, end_time:@end_time}).empty?
         true
    else
      false
    end
  end
end
