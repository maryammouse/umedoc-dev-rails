# == Schema Information
#
# Table name: medical_licenses
#
#  id                     :integer          not null, primary key
#  license_number         :string(255)      not null
#  first_issued_date      :date             not null
#  expiry_date            :date             not null
#  created_at             :datetime
#  updated_at             :datetime
#  doctor_id              :integer          not null
#  state_medical_board_id :integer          not null
#

class MedicalLicense < ActiveRecord::Base
  extend StateBoardValidity
  extend ForeignKeyValidity

  belongs_to :doctor, inverse_of: :medical_licenses
  belongs_to :state_medical_board, inverse_of: :medical_licenses
  has_many :temporary_credentials
  validates :doctor_id, presence: true, numericality: { only_integer: true }
  validate :validate_doctor_id_based_on_inclusion
  validates :license_number, presence: true, format: { with: /\A[-\w']+\Z/,
    message: "has characters our system can't handle. We're sorry!" }

  validates :state_medical_board_id, presence: true, numericality: { only_integer: true }
  validates :first_issued_date, presence: true
  validates :expiry_date, presence: true

  validates_date :first_issued_date,
    :after => lambda { 50.years.ago },
    :after_message => "is too long ago",
    :before => lambda { Time.now },
    :before_message => "is a date in the future"


  validates_date :expiry_date,
    :after => lambda { Time.now },
    :after_message => "is a date in the past"


  def validate_doctor_id_based_on_inclusion
    unless MedicalLicense.valid_doctor?(doctor_id)
      error_msg = "is not a valid doctor_id"
      errors.add(:doctor_id, error_msg)
    end
  end



end
