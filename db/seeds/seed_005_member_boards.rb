ActiveRecord::Base.transaction do
  board_array = [
  "American Board of Allergy and Immunology",
  "American Board of Anesthesiology",
  "American Board of Colon and Rectal Surgery",
  "American Board of Dermatology",
  "American Board of Emergency Medicine",
  "American Board of Family Medicine",
  "American Board of Internal Medicine",
  "American Board of Medical Genetics and Genomics",
  "American Board of Neurological Surgery",
  "American Board of Nuclear Medicine",
  "American Board of Obstetrics and Gynecology",
  "American Board of Ophthalmology",
  "American Board of Orthopaedic Surgery",
  "American Board of Otolaryngology",
  "American Board of Pathology",
  "American Board of Pediatrics",
  "American Board of Physical Medicine and Rehabilitation",
  "American Board of Plastic Surgery",
  "American Board of Preventive Medicine",
  "American Board of Psychiatry and Neurology",
  "American Board of Radiology",
  "American Board of Surgery",
  "American Board of Thoracic Surgery",
  "American Board of Urology",
  ]

  MemberBoard.delete_all

  board_array.uniq!
  board_array.sort!
  board_array.each do |board_name|
    MemberBoard.create(name: board_name)
  end
end
