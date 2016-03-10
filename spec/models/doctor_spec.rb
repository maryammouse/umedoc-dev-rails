# == Schema Information
#
# Table name: doctors
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  verification_status :text             default("not_verified"), not null
#  blurb               :text
#  linked_in           :string(255)
#  image               :text
#

require 'rails_helper'

  
describe "doctor", focus:false do
  it "is valid with all attributes filled" do
    credential = FactoryGirl.build(:doctor)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ user_id }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = FactoryGirl.build(:doctor,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['user_id', 'not_even_a_number', 'is not a number'],
    ['verification_status', 'not_the_right_verification_text', 'is not included in the list'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = FactoryGirl.build(:doctor,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "foreign keys" do
    it "is invalid without an existing doctor_id" do
      user = create(:user, id: 1)
      doctor = FactoryGirl.build(:doctor, user_id: 2) # not an existing user id
      doctor.valid?
      expect(doctor.errors[:user_id]).to include("is not a valid user id")
    end
  end

    context "Rails Associations" do
      describe Doctor do
        it { should have_many(:visits).through(:oncall_times) }
        it { should have_many(:oncall_times) }
        it { should have_many(:free_times).through(:oncall_times) }
        it { should belong_to(:user)}
        it { should have_many(:medical_licenses) }
        it { should have_many(:state_medical_boards).through(:medical_licenses) }
        it { should have_many(:office_locations) }
      end
    end
end
