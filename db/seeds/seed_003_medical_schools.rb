MedicalSchool.delete_all
medical_schools = SmarterCSV.process('db/data/world_medical_schools.csv')

medical_schools.each do |school|
  c = Country.find_by(name: school[:country_iso])
  school[:country_iso] = c[:iso] unless c == nil
  MedicalSchool.create school
end


