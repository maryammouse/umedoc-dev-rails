module StateBoardValidity
  extend ActiveSupport::Concern

  def valid_state_board?(state_medical_board_id)
    unless StateMedicalBoard.find_by(id: state_medical_board_id).nil?
      true
    else
      false
    end
  end
  
  def valid_state?(state_medical_board_id, valid_in)
    unless StateMedicalBoard.find_by(id: state_medical_board_id, state: valid_in ).nil?
      true
    else
      false
    end
  end
end
