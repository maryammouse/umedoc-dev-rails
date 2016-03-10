# == Schema Information
#
# Table name: time_outs
#
#  timerange      :tstzrange        not null
#  oncall_time_id :integer          not null
#  id             :integer          not null, primary key
#

class TimeOut < ActiveRecord::Base
  belongs_to :oncall_time, inverse_of: :time_outs
end
