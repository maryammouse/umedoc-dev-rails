# == Schema Information
#
# Table name: free_times
#
#  id                   :integer          not null, primary key
#  timerange            :tstzrange        not null
#  oncall_time_id       :integer          not null
#  duration             :integer          not null
#  online_visit_allowed :text             default("not_allowed"), not null
#  office_visit_allowed :text             default("not_allowed"), not null
#  area_visit_allowed   :text             default("not_allowed"), not null
#  online_visit_fee     :decimal(4, )     default(100), not null
#  office_visit_fee     :decimal(4, )     default(100), not null
#  area_visit_fee       :decimal(4, )     default(100), not null
#

class FreeTime < ActiveRecord::Base
  belongs_to :oncall_time
  has_many :fee_schedules, through: :oncall_times
  has_one :doctor, through: :oncall_time, inverse_of: :free_times

  def self.available_times(duration: 30.minutes,
                        query_time: Time.now.beginning_of_minute,
                        lead_time: 30.minutes,
                        num_free_times: 5)
    start_time = (query_time + lead_time).round_off 5.minutes

    end_time = (start_time + duration).round_off 5.minutes
    free_times = FreeTime.where("tstzrange(:start_time, :end_time) <@
                            free_times.timerange OR lower(timerange) > :cursor",
                                {start_time: start_time, end_time:end_time, cursor: start_time }).
        order(timerange: :asc)

    return free_times
  end

  def self.available(duration:30.minutes,
                        query_time:Time.now.beginning_of_minute,
                        lead_time:30.minutes,
                        num_free_times:5) #  TODO change name of parameter to num_visit_times (if still needed)
    # TODO consider method to count results and stop (or wait until needed to avoid 'coding while stupid'...)
    start_time = (query_time + lead_time).round_off 5.minutes
    end_time = (start_time + duration).round_off 5.minutes
    visit_duration_string = ((end_time - start_time)/60).round.to_s + ' minutes' # relies on both times being beginning_of_minute

    free_times_list = FreeTime.
      where('tstzrange(:start_time, :end_time) <@ free_times.timerange',
            {start_time: start_time, end_time:end_time}).order(:timerange).distinct


    free_times_visit_times = Hash.new

    free_times_list.each  do |free_time|
      free_time.slots(start_time:start_time, duration: duration).each do |potential_visit_time|
        if free_times_visit_times.key?(potential_visit_time)
          free_times_visit_times[potential_visit_time] << free_time
        else
          free_times_visit_times[potential_visit_time] = [free_time]
        end
      end
    end

    return free_times_visit_times
  end


  def self.next_available(duration:30.minutes,
                          query_time:Time.now.round_off(5.minutes),
                          lead_time:30.minutes,
                          num_free_times:5)
    start_time = (query_time + lead_time).round_off 5.minutes

    free_times_list = FreeTime.where("lower(timerange) > :cursor",
                                {cursor: start_time }).
                                order(timerange: :asc)

    free_times_visit_times = Hash.new

      free_times_list.each do |free_time|
        free_time.slots(start_time:free_time.timerange.begin.beginning_of_minute, duration: duration ).each do |potential_visit_time|
          if free_times_visit_times.key?(potential_visit_time)
            free_times_visit_times[potential_visit_time] << free_time
          else
            free_times_visit_times[potential_visit_time] = [free_time]
          end
        end
      end
    return free_times_visit_times
  end


  def self.all_available(duration:30.minutes,
                          query_time:Time.now.round_off(5.minutes),
                          lead_time:30.minutes,
                          num_free_times:5)

    free_times_visit_times = Hash.new
    current_available = self.available(duration:duration,
                                      query_time:query_time,
                                      lead_time:lead_time,
                                      num_free_times:num_free_times)
    next_available = self.next_available(duration:duration,
                                      query_time:query_time,
                                      lead_time:lead_time,
                                      num_free_times:num_free_times)
    current_available.keys.each do |potential_visit_time|
      if free_times_visit_times.key?(potential_visit_time)
        current_available[potential_visit_time].each do |free_time|
          free_times_visit_times[potential_visit_time] << free_time
        end
      else
        free_times_visit_times[potential_visit_time] = current_available[potential_visit_time ]
      end
    end
    next_available.keys.each do |potential_visit_time|
      if free_times_visit_times.key?(potential_visit_time)
        next_available[potential_visit_time].each do |free_time|
          free_times_visit_times[potential_visit_time] << free_time
        end
      else
        free_times_visit_times[potential_visit_time] = next_available[potential_visit_time]
      end
    end

    return free_times_visit_times
  end


  def slots(duration: 30.minutes,
          start_time: Time.at(timerange.begin.to_i/(5*60)*(5*60)))
    result = []
    if (start_time.beginning_of_minute < timerange.begin.beginning_of_minute) ||
      (start_time.beginning_of_minute > timerange.end.beginning_of_minute)
      return result
    end
    while (start_time + duration) <= timerange.end.beginning_of_minute
      result << start_time
      start_time += duration
    end
    #if result.empty?
    #  return nil
    #else
      return result
    #end
  end

end
