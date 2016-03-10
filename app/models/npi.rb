# == Schema Information
#
# Table name: npis
#
#  id          :integer          not null, primary key
#  npi_number  :string(255)      not null
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

class Npi < ActiveRecord::Base
  extend ReferenceNumber
  extend ForeignKeyValidity

  validates :doctor_id, presence: true, numericality: { only_integer: true }
  validate :validate_doctor_id_based_on_inclusion

  validates :npi_number, presence: true, numericality: { only_integer: true }
  validate :validate_npi_number_by_algorithm

  validates :valid_in, presence: true, inclusion: { in: ['US'] }

  validates :issued_date, presence: true
  validates_date :issued_date,
    :after => lambda { 35.years.ago },
    :after_message => "is too long ago",
    :before => lambda { Time.now },
    :before_message => "is a date in the future"
  
  def validate_npi_number_by_algorithm
    unless Npi.valid_npi?(npi_number)
      error_msg = "is not a valid npi number"
      errors.add(:npi_number, error_msg)
    end
  end

  def validate_doctor_id_based_on_inclusion
    unless Npi.valid_doctor?(doctor_id)
      error_msg = "is not a valid doctor id"
      errors.add(:doctor_id, error_msg)
    end
  end
end
