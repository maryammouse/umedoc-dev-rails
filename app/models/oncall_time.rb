# == Schema Information
#
# Table name: oncall_times
#
#  id              :integer          not null, primary key
#  doctor_id       :integer          not null
#  fee_schedule_id :integer          not null
#  timerange       :tstzrange        not null
#  bookable        :boolean          default(FALSE), not null
#  duration        :integer          not null
#

class OncallTime < ActiveRecord::Base
  extend OverlapValidator
  extend OncallTimeValidators

  belongs_to :doctor
  has_many :visits
  has_many :free_times
  has_many :time_outs, inverse_of: :oncall_time
  belongs_to :fee_schedule
  has_many :fee_rules, through: :fee_schedule
  has_many :oncall_times_online_locations
  has_many :online_locations, through: :oncall_times_online_locations
  has_many :office_locations, through: :oncall_times_office_locations
  has_many :oncall_times_office_locations

  validates :doctor_id, :fee_schedule_id, :timerange, presence: true

  validate :timerange_doctor_id_overlap_check

  validate :verified_doctor
  validate :connected_stripe

  def timerange_doctor_id_overlap_check
    if timerange.nil?
      return
    end
    unless OncallTime.valid_oncall_timerange?(doctor_id, timerange)
         errors.add(:timerange, "can't overlap an existing timerange")
    end
  end

  def verified_doctor
    unless OncallTime.doctor_verified?(doctor_id)
      errors.add(:doctor_id, "must be verified to input availability")
    end
  end

  def connected_stripe
    unless OncallTime.doctor_stripe?(doctor_id)
      errors.add(:doctor_id, "This doctor account has no stripe account connected.")
    end
  end

end
