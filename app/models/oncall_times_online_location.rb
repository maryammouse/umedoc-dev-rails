# == Schema Information
#
# Table name: oncall_times_online_locations
#
#  id                 :integer          not null, primary key
#  oncall_time_id     :integer          not null
#  online_location_id :integer          not null
#

class OncallTimesOnlineLocation < ActiveRecord::Base
  belongs_to :oncall_time
  belongs_to :online_location
end
