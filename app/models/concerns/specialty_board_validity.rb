module SpecialtyBoardValidity
  extend ActiveSupport::Concern

  def valid_board?(board_name)
    unless SpecialtyMemberBoard.find_by(board: board_name).nil?
      true
    else
      false
    end
  end

  def valid_specialty?(board_name, specialty)
    if SpecialtyMemberBoard.where(board: board_name, specialty: specialty).empty?
      false
    else
      true
    end
  end
end
