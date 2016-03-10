# == Schema Information
#
# Table name: oncall_times_online_locations
#
#  id                 :integer          not null, primary key
#  oncall_time_id     :integer          not null
#  online_location_id :integer          not null
#

require 'rails_helper'

RSpec.describe OncallTimesOnlineLocation, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
