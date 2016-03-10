module DoctorsHelper

  def valid_credentials?(temp_cred)
    @temporary_credential = TemporaryCredential.new
    if valid_state_board?(temp_cred[:state_medical_board_id]) and
      (valid_specialty?(temp_cred[:specialty_opt1]) or (temp_cred[:specialty_opt1] == '')) and
      (valid_specialty?(temp_cred[:specialty_opt2]) or temp_cred[:specialty_opt2] == '') and
      ((/\A^[^\W_]+\Z/ =~ temp_cred[:license_number])== 0) and
      (temp_cred[:is_general_practice] == '1' or temp_cred[:is_general_practice] == '0') and
      not_all_empty(temp_cred[:specialty_opt1], temp_cred[:specialty_opt2], temp_cred[:is_general_practice])
      true
    else
      if valid_state_board?(temp_cred[:state_medical_board_id]) == false
        @temporary_credential.errors.add(:state_medical_board_id,  "is not a medical board within our database")
      end
      if valid_specialty?(temp_cred[:specialty_opt1]) == false
        @temporary_credential.errors.add(:specialty_opt1, "is not a specialty within our database")
      end
      if valid_specialty?(temp_cred[:specialty_opt2]) == false
        @temporary_credential.errors.add(:specialty_opt2, "is not a specialty within our database")
      end
      if  (/\A^[^\W_]+\Z/ =~ temp_cred[:license_number]) == false or temp_cred[:license_number] == ''
        @temporary_credential.errors.add(:license_number, "is not a valid license number")
      end
      if temp_cred[:is_general_practice] != '0' and temp_cred[:is_general_practice] != '1'
        @temporary_credential.errors.add(:is_general_practice, "there is an issue with the general practice input")
      end
      unless not_all_empty(temp_cred[:specialty_opt2], temp_cred[:specialty_opt2], temp_cred[:is_general_practice])
        @temporary_credential.errors.add(:base, "You must either choose a specialty or be general practice")
      end
      false
    end
  end


  def valid_specialty?(specialty)
    unless Specialty.find_by(name: specialty).nil?
      true
    else
      false
    end
  end

  def valid_state_board?(state_medical_board)
    unless StateMedicalBoard.find_by(name: state_medical_board).nil?
      true
    else
      false
    end
  end

  def not_all_empty(specialty1, specialty2, is_general_practice )
    unless (specialty1 == '' and specialty2 == '' and is_general_practice == '0') or
           (specialty1 == 'None' and specialty2 == 'None' and is_general_practice == '0')
      true
    else
      false
    end
  end

end
