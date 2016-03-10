# == Schema Information
#
# Table name: malpractices
#
#  id               :integer          not null, primary key
#  policy_number    :string(255)      not null
#  valid_location   :string(255)      not null
#  policy_type      :string(255)      not null
#  coverage_amount  :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#  specialty        :string(255)      not null
#  doctor_id        :integer          not null
#  service_delivery :text             not null
#

require 'rails_helper'

describe "malpractice", focus:false do
  it "is valid with all attributes filled" do
    credential = build(:malpractice)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ doctor_id policy_number valid_location specialty policy_type coverage_amount service_delivery }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:malpractice,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "is invalid with incorrect:" do

    test_array = [['policy_number', 'not_a_number', 'is not a number'],
                  ['coverage_amount', 'not_even_a_number', 'is not a number'],
                  ['doctor_id', 'not_even_a_number', 'is not a number'],
                  ['policy_type', 'not an option!! lel', 'is not included in the list'],
                  ['valid_location', 'so_not_a_state!', 'is not a valid state'],
                  ['specialty', 'so_not_a_specials!', 'is not a valid specialty'],
                  ['service_delivery', 'not_valid', 'is not included in the list']
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:malpractice,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end


    describe "foreign key constraints" do
      it "is invalid without an existing doctor_id" do
        doctor = create(:doctor, id: 1) # the only real id
        credential = build(:malpractice, doctor_id: 2) # nonexistent doctor id
        credential.valid?
        expect(credential.errors[:doctor_id]).to include("is not a valid doctor id")
      end
    end
end
