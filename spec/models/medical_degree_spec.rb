# == Schema Information
#
# Table name: medical_degrees
#
#  id           :integer          not null, primary key
#  degree_type  :string(255)      not null
#  awarded_by   :string(255)      not null
#  date_awarded :date             not null
#  created_at   :datetime
#  updated_at   :datetime
#

require 'rails_helper'

describe "medical_degree", focus:false do
  it "is valid with all attributes filled" do
    credential = build(:medical_degree)
    credential.valid?
    expect(credential).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{degree_type awarded_by date_awarded }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:medical_degree,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end
  describe "is invalid with incorrect: " do
    test_array = [['degree_type', 'not_a_doc_degree', 'is not a valid degree type'],
                  ['awarded_by', 'not_a_real_place', 'is not a valid medical school'],
                  ['date_awarded', 'not_a_date', 'is not a valid date'],
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:medical_degree,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end
  describe "seperate tests" do

    it "works with a good awarded_by value" do
      credential = build(:medical_degree,
                         awarded_by: "University of Alabama School of Medicine",
                         degree_type: "Allopathic")
      credential.valid?
      expect(credential).to be_valid
    end

    it "does not work with a bad degree_type/awarded_by combo" do
      credential = build(:medical_degree,
                        awarded_by: "University of Alabama School of Medicine",
                        degree_type: "bad value Medical Degree - Osteopathic")
      credential.valid?
      expect(credential).to be_invalid
    end
  end
end
