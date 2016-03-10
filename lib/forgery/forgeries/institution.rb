require 'yaml'

class Forgery::Institution < Forgery

  def self.medical_school_md
    dictionaries[:medical_schools_md].random.unextend
  end

  def self.medical_school_do
    dictionaries[:medical_schools_do].random.unextend
  end

  def self.state_medical_board_md
    dictionaries[:state_medical_boards_md].random.unextend
  end

  def self.state_medical_board_do
    dictionaries[:state_medical_boards_do].random.unextend
  end

  def self.state_medical_board
    dictionaries[:state_medical_boards].random.unextend
  end

  def self.specialty_board
    board_name = SPECIALTY_BOARDS.keys.sample
    specialty_name = SPECIALTY_BOARDS[board_name]["specialty"].sample
    subspecialty_list = SPECIALTY_BOARDS[board_name]["subspecialty"]
    if subspecialty_list == nil
      subspecialty_name = nil
    else
      subspecialty_name = SPECIALTY_BOARDS[board_name]["subspecialty"].sample
    end
    return { specialty_board: board_name, specialty: specialty_name, subspecialty: subspecialty_name }
  end

#   SPECIALTY_BOARDS ={"American Board of Allergy and Immunology"=>{"specialty"=>["Allergy and Immunology"], "subspecialty"=>nil},
#                      "American Board of Anesthesiology"=>{"specialty"=>["Anesthesiology"], "subspecialty"=>["Critical Care Medicine", "Hospice and Palliative Medicine", "Pain Medicine", "Pediatric Anesthesiology", "Sleep Medicine"]},
#                      "American Board of Colon and Rectal Surgery"=>{"specialty"=>["Colon and Rectal Surgery"], "subspecialty"=>nil},
#                      "American Board of Dermatology"=>{"specialty"=>["Dermatology"], "subspecialty"=>["Dermatopathology", "Pediatric Dermatology"]},
#                      "American Board of Emergency Medicine"=>{"specialty"=>["Emergency Medicine"], "subspecialty"=>["Anesthesiology Critical Care Medicine", "Emergency Medical Services", "Hospice and Palliative Medicine", "Internal Medicine-Critical Care Medicine", "Medical Toxicology", "Pediatric Emergency Medicine", "Sports Medicine", "Undersea and Hyperbaric Medicine"]},
#                      "American Board of Family Medicine"=>{"specialty"=>["Family Medicine"], "subspecialty"=>["Adolescent Medicine", "Geriatric Medicine", "Hospice and Palliative Medicine", "Sleep Medicine", "Sports Medicine"]},
#                      "American Board of Internal Medicine"=>{"specialty"=>["Internal Medicine"], "subspecialty"=>["Adolescent Medicine", "Adult Congenital Heart Disease", "Advanced Heart Failure and Transplant Cardiology", "Cardiovascular Disease", "Clinical Cardiac Electrophysiology", "Critical Care Medicine", "Endocrinology, Diabetes and Metabolism", "Gastroenterology", "Geriatric Medicine", "Hematology", "Hospice and Palliative Medicine", "Infectious Disease", "Interventional Cardiology", "Medical Oncology", "Nephrology", "Pulmonary Disease", "Rheumatology", "Sleep Medicine", "Sports Medicine", "Transplant Hepatology"]},
#                      "American Board of Medical Genetics and Genomics"=>{"specialty"=>["Clinical Biochemical Genetics", "Clinical Cytogenetics", "Clinical Genetics (MD)", "Clinical Molecular Genetics"], "subspecialty"=>["Medical Biochemical Genetics", "Molecular Genetic Pathology"]},
#                      "American Board of Neurological Surgery"=>{"specialty"=>["Neurological Surgery"], "subspecialty"=>nil},
#                      "American Board of Nuclear Medicine"=>{"specialty"=>["Nuclear Medicine"], "subspecialty"=>nil},
#                      "American Board of Obstetrics and Gynecology"=>{"specialty"=>["Obstetrics and Gynecology"], "subspecialty"=>["Critical Care Medicine", "Female Pelvic Medicine and Reconstructive Surgery", "Gynecologic Oncology", "Hospice and Palliative Medicine", "Maternal and Fetal Medicine", "Reproductive Endocrinology/Infertility"]},
#                      "American Board of Ophthalmology"=>{"specialty"=>["Ophthalmology"], "subspecialty"=>nil},
#                      "American Board of Orthopaedic Surgery"=>{"specialty"=>["Orthopaedic Surgery"], "subspecialty"=>["Orthopaedic Sports Medicine", "Surgery of the Hand"]},
#                      "American Board of Otolaryngology"=>{"specialty"=>["Otolaryngology"], "subspecialty"=>["Neurotology", "Pediatric Otolaryngology", "Plastic Surgery Within the Head and Neck", "Sleep Medicine"]},
#                      "American Board of Pathology"=>{"specialty"=>["Pathology-Anatomic/Pathology-Clinical", "Pathology - Anatomic", "Pathology - Clinical"], "subspecialty"=>["Blood Banking/Transfusion Medicine", "Clinical Informatics", "Cytopathology", "Dermatopathology", "Neuropathology", "Pathology - Chemical", "Pathology - Forensic", "Pathology - Hematology", "Pathology - Medical Microbiology", "Pathology - Molecular Genetic", "Pathology - Pediatric"]},
#                      "American Board of Pediatrics"=>{"specialty"=>["Pediatrics"], "subspecialty"=>["Adolescent Medicine", "Child Abuse Pediatrics", "Developmental-Behavioral Pediatrics", "Hospice and Palliative Medicine", "Medical Toxicology", "Neonatal-Perinatal Medicine", "Neurodevelopmental Disabilities", "Pediatric Cardiology", "Pediatric Critical Care Medicine", "Pediatric Emergency Medicine", "Pediatric Endocrinology", "Pediatric Gastroenterology", "Pediatric Hematology-Oncology", "Pediatric Infectious Diseases", "Pediatric Nephrology", "Pediatric Pulmonology", "Pediatric Rheumatology", "Pediatric Transplant Hepatology", "Sleep Medicine", "Sports Medicine"]},
#                      "American Board of Physical Medicine and Rehabilitation"=>{"specialty"=>["Physical Medicine and Rehabilitation"], "subspecialty"=>["Brain Injury Medicine", "Hospice and Palliative Medicine", "Neuromuscular Medicine", "Pain Medicine", "Pediatric Rehabilitation Medicine", "Spinal Cord Injury Medicine", "Sports Medicine"]},
#                      "American Board of Plastic Surgery"=>{"specialty"=>["Plastic Surgery"], "subspecialty"=>["Plastic Surgery Within the Head and Neck", "Surgery of the Hand"]},
#                      "American Board of Preventive Medicine"=>{"specialty"=>["Aerospace Medicine*", "Occupational Medicine*", "Public Health and General Preventive Medicine"], "subspecialty"=>["Clinical Informatics", "Medical Toxicology", "Undersea and Hyperbaric Medicine"]},
#                      "American Board of Psychiatry and Neurology"=>{"specialty"=>["Psychiatry", "Neurology", "Neurology with Special Qualification in Child Neurology"], "subspecialty"=>["Addiction Psychiatry", "Brain Injury Medicine", "Child and Adolescent Psychiatry", "Clinical Neurophysiology", "Epilepsy", "Forensic Psychiatry", "Geriatric Psychiatry", "Hospice and Palliative Medicine", "Neurodevelopmental Disabilities", "Neuromuscular Medicine", "Pain Medicine", "Psychosomatic Medicine", "Sleep Medicine", "Vascular Neurology"]},
#                      "American Board of Radiology"=>{"specialty"=>["Diagnostic Radiology", "Interventional Radiology and Diagnostic Radiology", "Radiation Oncology", "Medical Physics"], "subspecialty"=>["Hospice and Palliative Medicine", "Neuroradiology", "Nuclear Radiology", "Pediatric Radiology", "Vascular and Interventional Radiology"]},
#                      "American Board of Surgery"=>{"specialty"=>["Surgery", "Vascular Surgery"], "subspecialty"=>["Complex General Surgical Oncology", "Hospice and Palliative Medicine", "Pediatric Surgery", "Surgery of the Hand", "Surgical Critical Care"]},
#                      "American Board of Thoracic Surgery"=>{"specialty"=>["Thoracic and Cardiac Surgery"], "subspecialty"=>["Congenital Cardiac Surgery"]},
#                      "American Board of Urology"=>{"specialty"=>["Urology"], "subspecialty"=>["Female Pelvic Medicine and Reconstructive Surgery", "Pediatric Urology"]}
#   }


SPECIALTY_BOARDS = YAML.load(
"American Board of Allergy and Immunology:
    specialty:
        - Allergy and Immunology
    subspecialty:
American Board of Anesthesiology:
    specialty:
        - Anesthesiology
    subspecialty:
        - Critical Care Medicine
        - Hospice and Palliative Medicine
        - Pain Medicine
        - Pediatric Anesthesiology
        - Sleep Medicine
American Board of Colon and Rectal Surgery:
    specialty:
        - Colon and Rectal Surgery
    subspecialty:
American Board of Dermatology:
    specialty:
        - Dermatology
    subspecialty:
        - Dermatopathology
        - Pediatric Dermatology
American Board of Emergency Medicine:
    specialty:
        - Emergency Medicine
    subspecialty:
        - Anesthesiology Critical Care Medicine
        - Emergency Medical Services
        - Hospice and Palliative Medicine
        - Internal Medicine-Critical Care Medicine
        - Medical Toxicology
        - Pediatric Emergency Medicine
        - Sports Medicine
        - Undersea and Hyperbaric Medicine
American Board of Family Medicine:
    specialty:
        - Family Medicine
    subspecialty:
        - Adolescent Medicine
        - Geriatric Medicine
        - Hospice and Palliative Medicine
        - Sleep Medicine
        - Sports Medicine
American Board of Internal Medicine:
    specialty:
        - Internal Medicine
    subspecialty:
        - Adolescent Medicine
        - Adult Congenital Heart Disease
        - Advanced Heart Failure and Transplant Cardiology
        - Cardiovascular Disease
        - Clinical Cardiac Electrophysiology
        - Critical Care Medicine
        - Endocrinology, Diabetes and Metabolism
        - Gastroenterology
        - Geriatric Medicine
        - Hematology
        - Hospice and Palliative Medicine
        - Infectious Disease
        - Interventional Cardiology
        - Medical Oncology
        - Nephrology
        - Pulmonary Disease
        - Rheumatology
        - Sleep Medicine
        - Sports Medicine
        - Transplant Hepatology
American Board of Medical Genetics and Genomics:
    specialty:
        - Clinical Biochemical Genetics
        - Clinical Cytogenetics
        - Clinical Genetics (MD)
        - Clinical Molecular Genetics
    subspecialty:
        - Medical Biochemical Genetics
        - Molecular Genetic Pathology
American Board of Neurological Surgery:
    specialty:
        - Neurological Surgery
    subspecialty:
American Board of Nuclear Medicine:
    specialty:
        - Nuclear Medicine
    subspecialty:
American Board of Obstetrics and Gynecology:
    specialty:
        - Obstetrics and Gynecology
    subspecialty:
        - Critical Care Medicine
        - Female Pelvic Medicine and Reconstructive Surgery
        - Gynecologic Oncology
        - Hospice and Palliative Medicine
        - Maternal and Fetal Medicine
        - Reproductive Endocrinology/Infertility
American Board of Ophthalmology:
    specialty:
        - Ophthalmology
    subspecialty:
American Board of Orthopaedic Surgery:
    specialty:
        - Orthopaedic Surgery
    subspecialty:
        - Orthopaedic Sports Medicine
        - Surgery of the Hand
American Board of Otolaryngology:
    specialty:
        - Otolaryngology
    subspecialty:
        - Neurotology
        - Pediatric Otolaryngology
        - Plastic Surgery Within the Head and Neck
        - Sleep Medicine
American Board of Pathology:
    specialty:
        - Pathology-Anatomic/Pathology-Clinical
        - Pathology - Anatomic
        - Pathology - Clinical
    subspecialty:
        - Blood Banking/Transfusion Medicine
        - Clinical Informatics
        - Cytopathology
        - Dermatopathology
        - Neuropathology
        - Pathology - Chemical
        - Pathology - Forensic 
        - Pathology - Hematology
        - Pathology - Medical Microbiology
        - Pathology - Molecular Genetic
        - Pathology - Pediatric
American Board of Pediatrics:
    specialty:
        - Pediatrics
    subspecialty:
        - Adolescent Medicine
        - Child Abuse Pediatrics
        - Developmental-Behavioral Pediatrics
        - Hospice and Palliative Medicine
        - Medical Toxicology
        - Neonatal-Perinatal Medicine
        - Neurodevelopmental Disabilities
        - Pediatric Cardiology
        - Pediatric Critical Care Medicine
        - Pediatric Emergency Medicine
        - Pediatric Endocrinology
        - Pediatric Gastroenterology
        - Pediatric Hematology-Oncology
        - Pediatric Infectious Diseases
        - Pediatric Nephrology
        - Pediatric Pulmonology
        - Pediatric Rheumatology
        - Pediatric Transplant Hepatology
        - Sleep Medicine
        - Sports Medicine
American Board of Physical Medicine and Rehabilitation:
    specialty:
        - Physical Medicine and Rehabilitation
    subspecialty:
        - Brain Injury Medicine
        - Hospice and Palliative Medicine
        - Neuromuscular Medicine
        - Pain Medicine
        - Pediatric Rehabilitation Medicine
        - Spinal Cord Injury Medicine
        - Sports Medicine
American Board of Plastic Surgery:
    specialty:
        - Plastic Surgery
    subspecialty:
        - Plastic Surgery Within the Head and Neck
        - Surgery of the Hand
American Board of Preventive Medicine:
    specialty:
        - Aerospace Medicine*
        - Occupational Medicine*
        - Public Health and General Preventive Medicine
    subspecialty:
        - Clinical Informatics
        - Medical Toxicology
        - Undersea and Hyperbaric Medicine
American Board of Psychiatry and Neurology:
    specialty:
        - Psychiatry
        - Neurology
        - Neurology with Special Qualification in Child Neurology
    subspecialty:
        - Addiction Psychiatry
        - Brain Injury Medicine
        - Child and Adolescent Psychiatry
        - Clinical Neurophysiology
        - Epilepsy
        - Forensic Psychiatry
        - Geriatric Psychiatry
        - Hospice and Palliative Medicine
        - Neurodevelopmental Disabilities
        - Neuromuscular Medicine
        - Pain Medicine
        - Psychosomatic Medicine
        - Sleep Medicine
        - Vascular Neurology
American Board of Radiology:
    specialty:
        - Diagnostic Radiology
        - Interventional Radiology and Diagnostic Radiology
        - Radiation Oncology
        - Medical Physics
    subspecialty:
        - Hospice and Palliative Medicine
        - Neuroradiology
        - Nuclear Radiology
        - Pediatric Radiology
        - Vascular and Interventional Radiology
American Board of Surgery:
    specialty:
        - Surgery
        - Vascular Surgery
    subspecialty:
        - Complex General Surgical Oncology
        - Hospice and Palliative Medicine
        - Pediatric Surgery
        - Surgery of the Hand
        - Surgical Critical Care
American Board of Thoracic Surgery:
    specialty:
        - Thoracic and Cardiac Surgery
    subspecialty:
        - Congenital Cardiac Surgery
American Board of Urology:
    specialty:
        - Urology
    subspecialty:
        - Female Pelvic Medicine and Reconstructive Surgery
        - Pediatric Urology
")
end
