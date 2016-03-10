# == Schema Information
#
# Table name: visits_office_locations
#
#  visit_id           :integer          not null
#  office_location_id :integer          not null
#  id                 :integer          not null, primary key
#

class VisitsOfficeLocation < ActiveRecord::Base
  belongs_to :visit
  belongs_to :office_location
end
