# == Schema Information
#
# Table name: office_locations
#
#  street_address_1 :string(64)       not null
#  street_address_2 :string(64)
#  city             :string(32)       not null
#  state            :string(2)        not null
#  zip_code         :string(5)        not null
#  id               :integer          not null, primary key
#  country          :text             not null
#  doctor_id        :integer
#

require 'rails_helper'

describe "OfficeLocation" do
  describe "OfficeLocation is valid with:" do

    it "is valid with a street_address_1, street_address_2, city, state, zip_code" do
      office_location = build(:office_location)
      office_location.valid?
      expect(office_location).to be_valid
    end
  end

  describe "OfficeLocation is invalid without: " do

    fields = %i{ street_address_1 city state zip_code }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        office_location = build(:office_location,
                    field => nil)
        office_location.valid?
        expect(office_location.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "OfficeLocation is invalid with incorrect:" do

    test_array =  [
               ['street_address_1', '!1!0 @ Bober Dr', "has characters our system can't handle. We're sorry!"],
               ['street_address_2', '!1!0 @ B0ber) Dr', "has characters our system can't handle. We're sorry!"],
               ['city', 'S@lt L@k3 Cit33', 'has invalid characters'],
               ['state', 'V@', 'has invalid characters'],
               ['state', 'Virginia', 'is the wrong length (should be 2 characters)'],
               ['zip_code', '31fs145sfa4', 'is not a valid zipcode in our database'],
    ]


    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          office_location = build(:office_location,
                      field_name => field_value)
          office_location.valid?
          expect(office_location.errors[field_name]).to include(field_error)
      end
    end
  end

   describe OfficeLocation do
    it { should have_many(:oncall_times_office_locations) }
    it { should have_many(:oncall_times).through(:oncall_times_office_locations) }
    it { should have_many(:visits_office_locations) }
    it { should have_many(:visits).through(:visits_office_locations) }
    it { should belong_to(:doctor) }

   end
end
