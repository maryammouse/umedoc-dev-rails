module OncallTimeValidators
  def doctor_stripe?(doctor_id)
    if Doctor.find_by(id: doctor_id).nil?
      false
    elsif Doctor.find_by(id: doctor_id).user.stripe_seller.nil?
      false
    else
      true
    end
  end

  def doctor_verified?(doctor_id)
    if Doctor.find_by(id: doctor_id).nil?
      false
    elsif Doctor.find_by(id: doctor_id).verification_status == 'verified'
      true
    else
      false
    end
  end
end
