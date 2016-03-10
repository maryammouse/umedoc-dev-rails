# == Schema Information
#
# Table name: npis
#
#  id          :integer          not null, primary key
#  npi_number  :string(255)      not null
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

require 'rails_helper'

describe "npi", focus:false do
  it "is valid with all attributes filled" do
    credential = build(:npi)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ doctor_id npi_number valid_in issued_date }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:npi,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['npi_number', 'not_even_a_number', 'is not a number'],
                  ['npi_number', 'AK0290389', 'is not a number'],
                  ['npi_number', '1234567895', 'is not a valid npi number'],
                  ['doctor_id', '1234567NOTNUM895', 'is not a number'],
                  ['valid_in', 'not_the_US', 'is not included in the list'],
                  ['issued_date', 'not_even_close', 'is not a valid date'],
                  ['issued_date', '1/1/1900', 'is too long ago'],
                  ['issued_date', '1/1/2100', 'is a date in the future'],
                  ['issued_date', '1', 'is not a valid date'],
                  ['issued_date', '123428429357295', 'is not a valid date'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:npi,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "foreign key constraints" do
    it "is invalid without an existing doctor_id" do
      doctor = create(:doctor, id: 1)
      npi = build(:npi, doctor_id: 2 )
      npi.valid?
      expect(npi.errors[:doctor_id]).to include("is not a valid doctor id")
    end
  end
end
