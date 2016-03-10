# == Schema Information
#
# Table name: malpractices
#
#  id               :integer          not null, primary key
#  policy_number    :string(255)      not null
#  valid_location   :string(255)      not null
#  policy_type      :string(255)      not null
#  coverage_amount  :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#  specialty        :string(255)      not null
#  doctor_id        :integer          not null
#  service_delivery :text             not null
#

class Malpractice < ActiveRecord::Base
  extend StateValidity
  extend SpecialtyValidity
  extend ForeignKeyValidity
  extend BooleanValidators

  belongs_to :doctors

  validates :doctor_id, presence: true, numericality: { only_integer: true }
  validate :validate_doctor_id_based_on_inclusion

  validates :policy_number, presence: true, numericality: { only_integer: true }

  validates :valid_location, presence: true
  validate :validate_location_based_on_inclusion

  validates :specialty, presence: true
  validate :validate_specialty_based_on_inclusion

  validates :service_delivery, presence: true, inclusion: { in: ['online', 'offline'] }

  validates :policy_type, presence: true, inclusion: { in: ['claims_made', 'occurrence_based'] }
  validates :coverage_amount, presence: true, numericality: true


  def telemedicine_and_in_person_are_not_both_false
    if Malpractice.both_false?(telemedicine, in_person)
      error_msg = "You must select either telemedicine, in_person, or both"
      errors.add(:base, error_msg)
    end
  end

  def validate_location_based_on_inclusion
    unless Malpractice.is_state?(valid_location)
      error_msg = "is not a valid state"
      errors.add(:valid_location, error_msg)
    end
  end

  def validate_specialty_based_on_inclusion
    unless Malpractice.valid_specialty?(specialty)
      error_msg = "is not a valid specialty"
      errors.add(:specialty, error_msg)
    end
  end

  def validate_doctor_id_based_on_inclusion
    unless Malpractice.valid_doctor?(doctor_id)
      error_msg = "is not a valid doctor id"
      errors.add(:doctor_id, error_msg)
    end
  end
end
