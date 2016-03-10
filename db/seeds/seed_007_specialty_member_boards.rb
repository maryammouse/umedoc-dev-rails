ActiveRecord::Base.transaction do
  SPECIALTY_BOARDS = YAML::load("
  American Board of Allergy and Immunology:
      specialty:
          - Allergy and Immunology
  American Board of Anesthesiology:
      specialty:
          - Anesthesiology
          - Critical Care Medicine
          - Hospice and Palliative Medicine
          - Pain Medicine
          - Pediatric Anesthesiology
          - Sleep Medicine
  American Board of Colon and Rectal Surgery:
      specialty:
          - Colon and Rectal Surgery
  American Board of Dermatology:
      specialty:
          - Dermatology
          - Dermatopathology
          - Pediatric Dermatology
  American Board of Emergency Medicine:
      specialty:
          - Emergency Medicine
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
          - Adolescent Medicine
          - Geriatric Medicine
          - Hospice and Palliative Medicine
          - Sleep Medicine
          - Sports Medicine
  American Board of Internal Medicine:
      specialty:
          - Internal Medicine
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
          - Medical Biochemical Genetics
          - Molecular Genetic Pathology
  American Board of Neurological Surgery:
      specialty:
          - Neurological Surgery
  American Board of Nuclear Medicine:
      specialty:
          - Nuclear Medicine
  American Board of Obstetrics and Gynecology:
      specialty:
          - Obstetrics and Gynecology
          - Critical Care Medicine
          - Female Pelvic Medicine and Reconstructive Surgery
          - Gynecologic Oncology
          - Hospice and Palliative Medicine
          - Maternal and Fetal Medicine
          - Reproductive Endocrinology/Infertility
  American Board of Ophthalmology:
      specialty:
          - Ophthalmology
  American Board of Orthopaedic Surgery:
      specialty:
          - Orthopaedic Surgery
          - Orthopaedic Sports Medicine
          - Surgery of the Hand
  American Board of Otolaryngology:
      specialty:
          - Otolaryngology
          - Neurotology
          - Pediatric Otolaryngology
          - Plastic Surgery Within the Head and Neck
          - Sleep Medicine
  American Board of Pathology:
      specialty:
          - Pathology-Anatomic/Pathology-Clinical
          - Pathology - Anatomic
          - Pathology - Clinical
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
          - Plastic Surgery Within the Head and Neck
          - Surgery of the Hand
  American Board of Preventive Medicine:
      specialty:
          - Aerospace Medicine
          - Occupational Medicine
          - Public Health and General Preventive Medicine
          - Clinical Informatics
          - Medical Toxicology
          - Undersea and Hyperbaric Medicine
  American Board of Psychiatry and Neurology:
      specialty:
          - Psychiatry
          - Neurology
          - Neurology with Special Qualification in Child Neurology
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
          - Hospice and Palliative Medicine
          - Neuroradiology
          - Nuclear Radiology
          - Pediatric Radiology
          - Vascular and Interventional Radiology
  American Board of Surgery:
      specialty:
          - Surgery
          - Vascular Surgery
          - Complex General Surgical Oncology
          - Hospice and Palliative Medicine
          - Pediatric Surgery
          - Surgery of the Hand
          - Surgical Critical Care
  American Board of Thoracic Surgery:
      specialty:
          - Thoracic and Cardiac Surgery
          - Congenital Cardiac Surgery
  American Board of Urology:
      specialty:
          - Urology
          - Female Pelvic Medicine and Reconstructive Surgery
          - Pediatric Urology
  ")

  SpecialtyMemberBoard.delete_all

  SPECIALTY_BOARDS.each do |key, value|
    puts " KEY " + key + " "
    if value["specialty"]
      value["specialty"].each do |subspecialty|
        SpecialtyMemberBoard.create(specialty: subspecialty, board: key)
      end
    end
  end
end
