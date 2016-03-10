MedicalSchool.delete_all
medical_schools = SmarterCSV.process('db/data/world_medical_schools.csv')

errors = []
medical_schools.each do |school|
  puts school
  c_name = school[:country_iso]
  c = Country.find_by(name: c_name)
  errors << c_name if c == nil
  school[:country_iso] = c[:iso] unless c == nil
  
end

