# == Schema Information
#
# Table name: visits_online_locations
#
#  visit_id           :integer          not null
#  online_location_id :integer          not null
#  id                 :integer          not null, primary key
#

class VisitsOnlineLocation < ActiveRecord::Base
  belongs_to :online_location
  belongs_to :visit
end
