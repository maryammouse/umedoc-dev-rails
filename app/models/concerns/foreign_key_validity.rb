module ForeignKeyValidity
  def valid_doctor?(foreign_doctor_key)
    unless Doctor.find_by(id: foreign_doctor_key).nil?
      true
    else
      false
    end
  end

  def valid_user?(foreign_user_key)
    unless User.find_by(id: foreign_user_key).nil?
      true
    else
      false
    end
  end

  def valid_oncall_time?(foreign_oncall_time_key)
    unless OncallTime.find_by(id: foreign_oncall_time_key).nil?
      true
    else
      false
    end
  end

  def valid_patient?(foreign_patient_key)
    unless Patient.find_by(id: foreign_patient_key).nil?
      true
    else
      false
    end
  end

  def valid_zipcode?(foreign_zipcode_key)
    unless ZipCode.find_by(zip: foreign_zipcode_key).nil?
      true
    else
      false
    end
  end

  def valid_state?(foreign_state_key)
    unless State.find_by(name: foreign_state_key).nil?
      true
    else
      false
    end
  end

end
