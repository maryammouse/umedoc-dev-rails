# == Schema Information
#
# Table name: zip_codes
#
#  zip                  :string(5)        not null, primary key
#  zip_type             :string(8)        not null
#  primary_city         :string(32)       not null
#  state                :string(2)        not null
#  county               :string(64)
#  timezone             :string(32)
#  area_codes           :string(64)
#  latitude             :float
#  longitude            :float
#  country              :string(2)
#  decommissioned       :boolean
#  estimated_population :integer
#  notes                :string(255)
#

require 'rails_helper'

RSpec.describe ZipCode, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
