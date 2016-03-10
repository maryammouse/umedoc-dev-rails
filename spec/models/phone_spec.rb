# == Schema Information
#
# Table name: phones
#
#  id         :integer          not null, primary key
#  number     :string(255)      not null
#  phone_type :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer          not null
#

require 'rails_helper'

describe "phone", focus:false do
  it "is valid with all attributes filled" do
    credential = build(:phone)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ user_id number phone_type }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:phone,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['number', 'not_a_number', 'is not a number'],
                  ['number', '1', 'is the wrong length (should be 10 characters)'],
                  ['number', '25923524242349234234', 'is the wrong length (should be 10 characters)'],
                  ['user_id', 'not_12_num', 'is not a number'],
                  ['phone_type', 'not_a_phone_type_OMG', 'is not included in the list'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:phone,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "foreign key constraints " do
    it "is invalid if the user_id does not exist" do
      user = create(:user, id: 1) # this is a valid foreign key
      phone = build(:phone, user_id: 2) # 2 is not a valid foreign key
      phone.valid?
      expect(phone.errors[:user_id]).to include("is not a valid user id")
    end
  end
end

