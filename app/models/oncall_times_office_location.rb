# == Schema Information
#
# Table name: oncall_times_office_locations
#
#  office_location_id :integer          not null
#  oncall_time_id     :integer          not null
#

class OncallTimesOfficeLocation < ActiveRecord::Base
  belongs_to :oncall_time
  belongs_to :office_location

  validates :office_location_id, presence: true
  validates :oncall_time_id, presence: true
end
