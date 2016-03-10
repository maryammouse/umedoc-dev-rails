# == Schema Information
#
# Table name: office_locations
#
#  street_address_1 :string(64)       not null
#  street_address_2 :string(64)
#  city             :string(32)       not null
#  state            :string(2)        not null
#  zip_code         :string(5)        not null
#  id               :integer          not null, primary key
#  country          :text             not null
#  doctor_id        :integer

class OfficeLocation < ActiveRecord::Base
  extend ForeignKeyValidity

  has_many :oncall_times_office_locations
  has_many :oncall_times, through: :oncall_times_office_locations
  has_many :visits_office_locations
  has_many :visits, through: :visits_office_locations
  belongs_to :doctor

  validates :street_address_1, presence: true, format: { with: /\A[0-9]*[-\w'\s]+\Z/,
    message: "has characters our system can't handle. We're sorry!"}

  validates :street_address_2, allow_blank: true, format: { with: /\A[0-9]*[-\w'\s]+\Z/,
    message: "has characters our system can't handle. We're sorry!"}

  validates :city, presence: true, format: { with: /\A[-\w'\s]+\Z/,
    message: "has invalid characters"}

  validates :state, presence: true, length: {is: 2}

  validates :state, presence: true, format: { with: /\A[\w]+\Z/,
    message: "has invalid characters"}


  validates :zip_code, presence: true
  validate :validate_zipcode_by_inclusion

  def validate_zipcode_by_inclusion
    unless OfficeLocation.valid_zipcode?(zip_code)
      error_msg = "is not a valid zipcode in our database"
      errors.add(:zip_code, error_msg)
    end
  end

end
