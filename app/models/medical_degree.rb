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

class MedicalDegree < ActiveRecord::Base
  extend Schools

  
  validates :degree_type, presence: true, 
    inclusion: { in: ["Allopathic",
                      "Osteopathic"],
                      message: "is not a valid degree type"
                }
  #validate :validate_awarded_by_inclusion_dependent_on_degree_type
  validate :validate_awarded_by_based_on_medical_school_table

  validates :awarded_by, presence: true

  validates :date_awarded, presence: true
  validates_date :date_awarded,
    :after => lambda { 30.years.ago }

  def validate_awarded_by_based_on_medical_school_table
    
    valid_schools = MedicalDegree.medical_schools
    unless valid_schools.include?(awarded_by)
      error_msg = "is not a valid medical school"
      errors.add(:awarded_by, error_msg)
    end
  end



  #def validate_awarded_by_inclusion_dependent_on_degree_type
    #valid_awarded_by_values = MedicalDegree.schools(degree_type)
#
    #if valid_awarded_by_values.nil?
      #error_msg = "is not a valid degree_type"
      #errors.add(:awarded_by, error_msg)
      #return
    #end
#
    #unless valid_awarded_by_values.include?(awarded_by)
      #error_msg = "is not a valid awarded_by"
      #errors.add(:awarded_by, error_msg)
    #end
  #end
end
