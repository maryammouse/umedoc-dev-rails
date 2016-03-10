# == Schema Information
#
# Table name: patients
#
#  id      :integer          not null, primary key
#  user_id :integer          not null
#

require 'rails_helper'

describe "patient", focus:true do
  it "is valid with all attributes filled" do
    credential = build(:patient)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ user_id }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:patient,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['user_id', 'not_12_num', 'is not a number'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:patient,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "foreign key constraints " do
    it "is invalid if the user_id does not exist" do
      user = create(:user, id: 1) # this is a valid foreign key
      phone = build(:patient, user_id: 2) # 2 is not a valid foreign key
      phone.valid?
      expect(phone.errors[:user_id]).to include("is not a valid user id")
    end
  end

  describe Patient do
    it { should belong_to(:user) }
  end
end
