module Schools
  extend ActiveSupport::Concern

  def medical_schools
    #MedicalSchool.find_by name: awarded_by
    #schools_list = MedicalSchool.all
    #valid_awarded_by_values = []
    #schools_list.each do |school|
      #valid_awarded_by_values << school.name
    #end
    
    valid_awarded_by_values = MedicalSchool.pluck(:name)
    #valid_awarded_by_values
  end
end
