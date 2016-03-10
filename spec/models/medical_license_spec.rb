# == Schema Information
#
# Table name: medical_licenses
#
#  id                     :integer          not null, primary key
#  license_number         :string(255)      not null
#  first_issued_date      :date             not null
#  expiry_date            :date             not null
#  created_at             :datetime
#  updated_at             :datetime
#  doctor_id              :integer          not null
#  state_medical_board_id :integer          not null
#

require 'rails_helper'

describe MedicalLicense, focus:false do

  context "Rails Associations" do
      describe MedicalLicense do
        it { should belong_to(:doctor) }
        it { should belong_to(:state_medical_board)}
      end
    end

  it "is valid with all attributes filled" do
    credential = FactoryGirl.create(:medical_license)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{doctor_id state_medical_board_id license_number first_issued_date expiry_date }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:medical_license,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  
  describe "is invalid with incorrect:" do
    test_array = [['license_number', 'n@@ot_a_license111214', "has characters our system can't handle. We're sorry!"],
                  ['doctor_id', 'not_a_number', 'is not a number'],
                  #['license_number', '1', 'must be 10 digits long'],
                  #['license_number', '10000000000000', 'must be 10 digits long'],
                  ['state_medical_board_id', 'not_a_number', 'is not a number'],
                  ['first_issued_date', 'not_a_date_or_even_a_number', 'is not a valid date'],
                  ['first_issued_date', '11190002324324', 'is not a valid date'],
                  ['first_issued_date', '1/5/1900', 'is too long ago'],
                  ['first_issued_date', '1/5/2100', 'is a date in the future'],
                  ['first_issued_date', '1', 'is not a valid date'],
                  ['expiry_date', 'not even a number, mate!', 'is not a valid date'],
                  ['expiry_date', '1110000', 'is not a valid date'],
                  ['expiry_date', '1/5/1900', 'is a date in the past'],
                  ['expiry_date', '1', 'is not a valid date'],
    ]


    test_array.each do |field_name, field_value, field_error|
      it "is invalid with incorrect #{ field_name }: #{ field_value } " do
        credential = build(:medical_license,
                    field_name => field_value)
        credential.valid?
        expect(credential.errors[field_name]).to include(field_error)
      end
    end
  end


  describe "foreign key doctor_id" do
    it "works if the doctor_id is in in the doctors table" do
      user = create(:user, id: 1)
      doctor = create(:doctor, user_id: 1)
      license = build(:medical_license, doctor_id: doctor.id)
      license.valid?
      expect(license).to be_valid
    end

    it "does not work if the doctor_id is not in the doctors table" do
      user = create(:user, id: 1)
      doctor = create(:doctor, user_id: user.id, id: 3) # this doctor id exists
      license = build(:medical_license, doctor_id: 5) # nonexistent doctor id
      license.valid?
      expect(license).to be_invalid
    end
  end
end
