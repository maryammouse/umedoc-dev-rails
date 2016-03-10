# == Schema Information
#
# Table name: temporary_credentials
#
#  specialty_opt1         :string(255)      not null
#  specialty_opt2         :string(255)      not null
#  license_number         :string(20)       not null
#  doctor_id              :integer          not null
#  is_general_practice    :text             default("0"), not null
#  state_medical_board_id :integer
#  id                     :integer          not null, primary key
#

require 'rails_helper'

describe "temporary_credential", focus:false do
  it "is valid with all attributes filled" do
    credential = build(:temporary_credential)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ doctor_id license_number state_medical_board_id}
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:temporary_credential,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['license_number', '@invalidchar@cters1231!', 'is not a valid license number'],
                  ['state_medical_board_id', 'not_a_real_id', 'is not a valid state medical board'],
                  ['specialty_opt1', 'not_even_a_specialty', 'is not a valid specialty'],
                  ['specialty_opt2', 'not_a_specialty_either', 'is not a valid specialty'],
                  ['doctor_id', 'not_an_id_clearly', 'is not a number'],
                  ['is_general_practice', 'not_an_gen_clearly', 'is not included in the list'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:temporary_credential,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end



  describe "invalid if no specialty/practice specified:" do
    it "is invalid if both specialty_opts and general_practice are not true" do
      credential = build(:temporary_credential, is_general_practice: '0' ,
                        specialty_opt1: '', specialty_opt2: '' )
      credential.valid?
      expect(credential).to be_invalid
    end
  end

  describe "specialty opts are valid if blank" do
    it "is valid if general practice is true and specialty opts are blank" do
      credential = build(:temporary_credential, is_general_practice: '1',
                        specialty_opt1: '',
                        specialty_opt2: '')
      credential.valid?
      expect(credential).to be_valid
    end
    it "is valid if specialty_opt1 is blank" do
      credential = build(:temporary_credential,
                        specialty_opt1: '')
      credential.valid?
      expect(credential).to be_valid
    end
    it "is valid if specialty_opt2 is blank" do
      credential = build(:temporary_credential,
                        specialty_opt2: '')
      credential.valid?
      expect(credential).to be_valid
    end
  end
end

