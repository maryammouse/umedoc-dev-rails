# == Schema Information
#
# Table name: addresses
#
#  id               :integer          not null, primary key
#  address_type     :string(255)
#  street_address_1 :string(255)      not null
#  street_address_2 :string(255)
#  city             :string(255)      not null
#  state            :string(255)      not null
#  zip_code         :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#  mailing_name     :string(255)      not null
#  latitude         :float
#  longitude        :float
#  user_id          :integer          not null
#

require 'rails_helper'

describe "Address", focus:false do

  describe "Address is valid with:" do

      it "is valid with a mailing_name, street_address_1, city, state, zip_code, and user_id but no optional ones" do
        VCR.use_cassette "geolocation_cassette_1" do
          user = create(:user)
          address = build(:address, user_id: user.id,
                          address_type: nil, street_address_2: nil)
          address.valid?
          expect(address).to be_valid
        end
      end

      it "is valid with all attributes" do
        VCR.use_cassette "geolocation_cassette_0" do
          user = create(:user)
          address = build(:address, user_id: user.id)
          address.valid?
          expect(address).to be_valid
        end
      end

  end

  describe "address is invalid without: " do

    fields = %i{ user_id mailing_name street_address_1 city state zip_code }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        VCR.use_cassette "geolocation_cassette_2", :record => :new_episodes do
          address = build(:address,
                      field => nil)
          address.valid?
          expect(address.errors[field]).to include("can't be blank")
        end
      end
    end
  end

  describe "address is invalid with incorrect: " do

    test_array =  [
               ['user_id',  'not a number', "is not a number"],
               ['mailing_name',  'Princess@nna', "We're sorry, our system can't handle that mailing name."],
               ['street_address_1',  'Princess@nna', "We're sorry, our system can't handle that street address."],
               ['street_address_2',  'Princess@nna', "We're sorry, our system can't handle that street address."],
               ['address_type',  'Princess@nna', "We're sorry, our system can't handle that address type."],
               ['city',  'Princess@nna', "We're sorry, our system can't handle that city name."],
               ['state',  'Princess@nna', "The state must be in abbreviated form (two letters)."],
               ['zip_code',  'Princess@nna', "is not a number"],
               ['zip_code',  '1000104', "is the wrong length (should be 5 characters)"],
               ['zip_code',  '1', "is the wrong length (should be 5 characters)"],
      ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          VCR.use_cassette "geolocation_cassette_3", :record => :new_episodes do
            address = build(:address,
                        field_name => field_value)
            address.valid?
            expect(address.errors[field_name]).to include(field_error)
          end
      end
    end
  end

  describe "address foreign keys" do
    it "is valid if the foreign key is valid" do
      VCR.use_cassette "geolocation_cassette_0" do
        user = create(:user)
        address = build(:address, user_id: user.id)
        address.valid?
        expect(address).to be_valid
      end
    end

    it "is invalid if the foreign key does not exist" do
      VCR.use_cassette "geolocation_cassette_0" do
        user = create(:user, id: 1) # this is a valid foreign key
        address = build(:address, user_id: 2) # 2 is not a valid foreign key
        address.valid?
        expect(address).to be_invalid
      end
    end

  end
end

