module FeeSchedulesHelper
  def rules_by_day_iterator(fee_schedule, day_of_week)
    fs = FeeSchedule.find_by(id: fee_schedule.id)
    fs.fee_rules.where(day_of_week: day_of_week).order(time_of_day_range: :asc)
  end
end
