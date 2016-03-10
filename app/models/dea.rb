# == Schema Information
#
# Table name: deas
#
#  dea_number  :string(255)      not null, primary key
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  expiry_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

class Dea < ActiveRecord::Base
  extend ReferenceNumber
  extend StateValidity
  extend ForeignKeyValidity

  validates :doctor_id, presence:true, numericality: { only_integer: true }
  validate :validate_doctor_id_based_on_inclusion

  validates :dea_number, presence: true
  validate :validate_dea_number_by_algorithm

  validates :valid_in, presence: true
  validate :validate_valid_in_based_on_inclusion
  
  validates :issued_date, presence: true
  validates :expiry_date, presence: true

  validates_date :issued_date,
    :after => lambda { 3.years.ago },
    :after_message => "is too long ago",
    :before => lambda { Time.now },
    :before_message => "is a date in the future"

  validates_date :expiry_date,
    :after => lambda { Time.now + 1.month },
    :after_message => "is either too soon or in the past"

  def validate_dea_number_by_algorithm
    unless Dea.valid_dea?(dea_number)
      error_msg = "is not a valid dea number"
      errors.add(:dea_number, error_msg)
    end
  end

  def validate_valid_in_based_on_inclusion
    unless Dea.is_state?(valid_in)
      error_msg = "is not a valid state"
      errors.add(:valid_in, error_msg)
    end
  end

  def validate_doctor_id_based_on_inclusion
    unless Dea.valid_doctor?(doctor_id)
      error_msg = "is not a valid doctor id"
      errors.add(:doctor_id, error_msg)
    end
  end
end
