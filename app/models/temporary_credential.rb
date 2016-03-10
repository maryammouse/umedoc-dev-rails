# == Schema Information
#
# Table name: temporary_credentials
#
#  specialty_opt1         :string(255)      not null
#  specialty_opt2         :string(255)      not null
#  license_number         :string(20)       not null
#  doctor_id              :integer          not null
#  is_general_practice    :text             default("0"), not null
#  state_medical_board_id :integer
#  id                     :integer          not null, primary key
#

class TemporaryCredential < ActiveRecord::Base
  extend StateBoardValidity
  extend SpecialtyValidity
  belongs_to :doctor
  belongs_to :medical_license
  belongs_to :state_medical_board

  validates :doctor_id, presence: true, numericality: { only_integer: true }
  validates :license_number, presence: true, format: { with: /\A[\w{.,'}+:?®©-]+\Z/,
  message: "is not a valid license number" }

  validates :state_medical_board_id, presence: true
  validate :validates_medical_board_by_inclusion

  validates :is_general_practice, inclusion: { in: ['0', '1' ] }

  validate :any_present?


  validate :validates_specialty_opt1
  validate :validates_specialty_opt2

  def any_present?
    if (is_general_practice == '0') and (specialty_opt1 == '') and (specialty_opt2 == '')
      errors.add :base, "You must either offer a specialty or be a general practice"
    end
  end

  def validates_medical_board_by_inclusion
    unless TemporaryCredential.valid_state_board?(state_medical_board_id)
      error_msg = "is not a valid state medical board"
      errors.add(:state_medical_board_id, error_msg)
    end
  end

  def validates_specialty_opt1
    unless TemporaryCredential.valid_specialty?(specialty_opt1) or (specialty_opt1 == '')
      error_msg = "is not a valid specialty"
      errors.add(:specialty_opt1, error_msg)
    end
  end

  def validates_specialty_opt2
    unless TemporaryCredential.valid_specialty?(specialty_opt2) or (specialty_opt2 == '')
      error_msg = "is not a valid specialty"
      errors.add(:specialty_opt2, error_msg)
    end
  end
end
