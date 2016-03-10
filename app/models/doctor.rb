# == Schema Information
#
# Table name: doctors
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  verification_status :text             default("not_verified"), not null
#  blurb               :text
#  linked_in           :string(255)
#  image               :text
#

class Doctor < ActiveRecord::Base
  extend ForeignKeyValidity
  extend BooleanValidators

  has_many :visits, through: :oncall_times
  has_many :oncall_times
  has_many :free_times, through: :oncall_times
  belongs_to :user
  has_one :stripe_seller, through: :user
  has_one :malpractices, inverse_of: :doctors
  has_many :medical_licenses, inverse_of: :doctor
  has_many :state_medical_boards, through: :medical_licenses
  has_many :fee_schedules, inverse_of: :doctor
  has_many :promotions
  has_many :office_locations

  validates :user_id, presence: true, numericality: { only_integer: true }
  validate :validate_user_id_by_inclusion

  validates :verification_status, allow_blank: true, inclusion: { in: [ 'not_verified', 'verified' ] }
  #validate :validate_verified_boolean

  def validate_user_id_by_inclusion
    unless Doctor.valid_user?(user_id)
      error_msg = "is not a valid user id"
      errors.add(:user_id, error_msg)
    end
  end

#  def validate_verified_boolean
    #unless Doctor.boolean?(verified)
      #error_msg = "is not a valid boolean"
      #errors.add(:verified, error_msg)
    #end
  #end
end
