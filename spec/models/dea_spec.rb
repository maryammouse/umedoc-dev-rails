# == Schema Information
#
# Table name: deas
#
#  dea_number  :string(255)      not null, primary key
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  expiry_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

require 'rails_helper'

describe "dea", focus:false do
  it "is valid with all attributes filled" do
    user = create(:user)
    doctor = create(:doctor, user_id: user.id)
    credential = build(:dea, doctor_id: doctor.id)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ doctor_id dea_number valid_in issued_date expiry_date }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:dea,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['dea_number', 'not_even_a_number', 'is not a valid dea number'],
                  ['dea_number', 'AK0290389', 'is not a valid dea number'],
                  ['doctor_id', 'not_a_num', 'is not a number'],
                  ['valid_in', 'not_a_state', 'is not a valid state'],
                  ['issued_date', 'not_even_close', 'is not a valid date'],
                  ['issued_date', '1/1/1900', 'is too long ago'],
                  ['issued_date', '1/1/2100', 'is a date in the future'],
                  ['issued_date', '1', 'is not a valid date'],
                  ['issued_date', '123428429357295', 'is not a valid date'],
                  ['expiry_date', 'not_even_close', 'is not a valid date'],
                  ['expiry_date', '1/1/1900', 'is either too soon or in the past'],
                  ['expiry_date', '1', 'is not a valid date'],
                  ['expiry_date', '123428429357295', 'is not a valid date'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:dea,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "foreign keys" do
    it "is invalid without an existing doctor_id" do
      user = create(:user)
      doctor = create(:doctor, user_id: user.id, id: 1) # the only real id
      credential = build(:dea, doctor_id: 2) # nonexistent doctor id
      credential.valid?
      expect(credential.errors[:doctor_id]).to include("is not a valid doctor id")
    end

  end
end
