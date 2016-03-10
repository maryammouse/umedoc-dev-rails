# == Schema Information
#
# Table name: online_locations
#
#  state      :string(2)        not null
#  country    :string(2)        not null
#  id         :integer          not null, primary key
#  state_name :text             not null
#

require 'rails_helper'

describe "OnlineLocation" do
  describe "OnlineLocation is valid with:" do

    it "is valid with a state, country, state_name" do
      online_location = build(:online_location)
      online_location.valid?
      expect(online_location).to be_valid
    end
  end

  describe "OnlineLocation is invalid without: " do

    fields = %i{ state country state_name }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        online_location = build(:online_location,
                    field => nil)
        online_location.valid?
        expect(online_location.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "OnlineLocation is invalid with incorrect:" do

    test_array =  [
               ['state', 'V@', 'has invalid characters'],
               ['state', 'Virginia', 'is the wrong length (should be 2 characters)'],
               ['country', 'Un!t3d $t@t3s lel', 'has invalid characters'],
               ['state_name', 'V!rg!n!@)', 'has invalid characters'],
               ['state_name', 'Mexico', 'is not a valid state in our database'],
    ]


    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          online_location = build(:online_location,
                      field_name => field_value)
          online_location.valid?
          expect(online_location.errors[field_name]).to include(field_error)
      end
    end
  end

   describe OnlineLocation do
    it { should have_many(:oncall_times_online_locations) }
    it { should have_many(:oncall_times).through(:oncall_times_online_locations) }
    it { should have_many(:visits_online_locations) }
    it { should have_many(:visits).through(:visits_online_locations) }
   end
end
