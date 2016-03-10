# == Schema Information
#
# Table name: visits
#
#  id             :integer          not null, primary key
#  session_id     :text             not null
#  oncall_time_id :integer          not null
#  patient_id     :integer          not null
#  timerange      :tstzrange        not null
#  fee_paid       :integer          not null
#  duration       :integer          not null
#  jurisdiction   :text             default("not_accepted"), not null
#  authenticated  :string(1)        default("0"), not null
#

class Visit < ActiveRecord::Base
  before_validation :set_column_from_sequence
  #before_save :check_timerange_overlap

  after_validation :overlap_check

  before_save :stripe_charge

  extend ForeignKeyValidity
  extend TimerangeValidators
  include TwilioSms

  belongs_to :oncall_time
  belongs_to :patient
  belongs_to :doctor
  has_one :office_location, through: :visits_office_location
  has_one :visits_office_location
  has_many :online_locations, through: :visits_online_locations
  has_many :visits_online_locations

  validates :oncall_time_id, presence: true, numericality: { only_integer: true }
  validate :validate_oncall_time_id_fkey

  validates :timerange, presence: true
  validate :timerange_validity

  validates :patient_id, presence: true, numericality: { only_integer: true }
  validate :validate_patient_id_fkey

  validates :session_id, presence: true, format: { with: /\A[a-zA-Z0-9_-]*\Z/ }

  validates :authenticated, presence: true, inclusion: { in: ['1', '0'] }



  def validate_patient_id_fkey
    unless Visit.valid_patient?(patient_id)
      error_msg = "is not a valid patient id"
      errors.add(:patient_id, error_msg)
    end
  end

  def timerange_validity
    unless Visit.start_before_end?(timerange)
      error_msg = "ends before it starts, which is impossible (unless you're a time traveler.) Please try again!"
      errors.add(:timerange, error_msg)
    end
  end

  def validate_oncall_time_id_fkey
    unless Visit.valid_oncall_time?(oncall_time_id)
      error_msg = "is not a valid oncall time id"
      errors.add(:oncall_time_id, error_msg)
    end
  end


  def stripe_charge
    #puts 'callback running - stripe charge'

    if fee_paid > 0
      puts patient
      customer_token = Stripe::Token.create(
          { customer: patient.user.stripe_customer.customer_id} ,
          oncall_time.doctor.user.stripe_seller.access_token # DOCTOR'S access token
      )

      #puts customer_token

      begin
      charge = Stripe::Charge.create(
      {
          :amount => fee_paid,
          :currency => "usd",
          :source => customer_token.id,
          :application_fee => (fee_paid * 0.1).round
      }, oncall_time.doctor.user.stripe_seller.access_token
      )
    rescue => e
      errors.add(:fee_paid, e.message)
      puts e.message
      raise "Unable to make a charge"
      end
    end
  end

  private
    def set_column_from_sequence
      if self.session_id.nil?
        self.session_id = self.class.connection.select_value("SELECT nextval('visits_session_id_seq')")
      end
    end

  def overlap_check
    if oncall_time_id and Visit.start_before_end?(timerange)
      ot = OncallTime.find_by(id: oncall_time_id)
      if ot
          ft = FreeTime.where(oncall_time_id: ot.id).where('tstzrange(:start_time, :end_time) <@ free_times.timerange',
                {start_time: timerange.begin, end_time: timerange.end})
          unless ft.present?
            errors.add(:timerange, "We're very sorry, this visit is no longer available. Please book another!")
            raise "There is no free_time belonging to the oncall_time that can contain this visit timerange"
          end
      end
    end
  end

end
