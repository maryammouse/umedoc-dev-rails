# == Schema Information
#
# Table name: board_certifications
#
#  id                   :integer          not null, primary key
#  board_name           :string(255)      not null
#  created_at           :datetime
#  updated_at           :datetime
#  certification_number :string(255)      not null
#  expiry_date          :date             not null
#  issue_date           :date             not null
#  specialty            :string(255)      not null
#  doctor_id            :integer          not null
#

class BoardCertification < ActiveRecord::Base
  extend SpecialtyBoardValidity
  extend ForeignKeyValidity

  validates :doctor_id, presence: true, numericality: { only_integer: true }
  validate :validate_doctor_id_by_inclusion

  validates :specialty, presence: true
  validates :board_name, presence: true
  validates :issue_date, presence: true
  validates :expiry_date, presence: true
  validates :certification_number, presence: true,
    numericality: { only_integer: true },
    length: { maximum: 20 }

  validate :validate_specialty_based_on_board_name
  validate :validate_board_name_is_in_dict

  validates_date :issue_date,
    :after => lambda { 10.years.ago },
    :after_message => "is too long ago",
    :before => lambda { Time.now },
    :before_message => "is a date in the future"

  validates_date :expiry_date,
    :after => lambda { Time.now + 1.month },
    :after_message => "is either too soon or in the past"

  def validate_specialty_based_on_board_name
    truth = BoardCertification.valid_specialty?(board_name, specialty)
    if truth == false
      error_msg = "is not a valid specialty"
      errors.add(:specialty, error_msg)
    end
  end

  def validate_board_name_is_in_dict
    truth = BoardCertification.valid_board?(board_name)
    if truth == false
      error_msg = "is not a valid board"
      errors.add(:board_name, error_msg)
    end
  end

  def validate_doctor_id_by_inclusion
    unless BoardCertification.valid_doctor?(doctor_id)
      error_msg = "is not a valid doctor id"
      errors.add(:doctor_id, error_msg)
    end
  end

  
end
