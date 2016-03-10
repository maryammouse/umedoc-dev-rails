# == Schema Information
#
# Table name: board_certifications
#
#  id                   :integer          not null, primary key
#  board_name           :string(255)      not null
#  created_at           :datetime
#  updated_at           :datetime
#  certification_number :string(255)      not null
#  expiry_date          :date             not null
#  issue_date           :date             not null
#  specialty            :string(255)      not null
#  doctor_id            :integer          not null
#

require 'rails_helper'

describe "board_certification", focus:false do
  it "is valid with all attributes filled" do
    user = create(:user)
    doctor = create(:doctor, user_id: user.id)
    credential = build(:board_certification, doctor_id: doctor.id)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ doctor_id specialty board_name issue_date expiry_date certification_number }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:board_certification,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['specialty', 'not_a_speciality', 'is not a valid specialty'],
                  ['doctor_id', 'not_a_number', 'is not a number'],
                  ['board_name', 'not_a_real_board', 'is not a valid board'],
                  ['issue_date', 'not_a_date', 'is not a valid date'],
                  ['issue_date', '1', 'is not a valid date'],
                  ['issue_date', '1/1/1000', 'is too long ago'],
                  ['issue_date', '1/1/2100', 'is a date in the future'],
                  ['issue_date', '98072396491234', 'is not a valid date'],
                  ['expiry_date', '98072396491234', 'is not a valid date'],
                  ['expiry_date', 'not_a_date', 'is not a valid date'],
                  ['expiry_date', '1', 'is not a valid date'],
                  ['expiry_date', '1/1/1000', 'is either too soon or in the past'],
                  ['expiry_date', '1/1/2000', 'is either too soon or in the past'],
                  ['certification_number', 'not_a_num', 'is not a number'],
                  ['certification_number', '423472935257252934234242343234', 'is too long (maximum is 20 characters)'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:board_certification,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "certification_number specific:" do
    it "is valid with a number less than 20 digits" do
      user = create(:user)
      doctor = create(:doctor, user_id: user.id)
      credential = build(:board_certification, doctor_id: doctor.id,
                        certification_number: "23425")
      credential.valid?
      expect(credential).to be_valid

    end
  end

  describe "expiry_date specific:" do
    it "is invalid if expiring within a month" do
      credential= build(:board_certification,
                       expiry_date: Time.now + 1.week )
      credential.valid?
      expect(credential).to be_invalid
    end
  end

  describe "foreign key specific" do
    it "is valid if the foreign key exists" do
      user = create(:user)
      doctor = create(:doctor, user_id: user.id)
      credential = build(:board_certification, doctor_id: doctor.id)
      credential.valid?
      expect(credential).to be_valid
    end

    it "is invalid if the foreign key does not exist" do
      user = create(:user)
      doctor = create(:doctor, user_id: user.id, id: 1) # only doctor that exists
      credential = build(:board_certification, doctor_id: 2) # nonexistent doctor id
      credential.valid?
      expect(credential).to be_invalid
    end
  end
end
