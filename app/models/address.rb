# == Schema Information
#
# Table name: addresses
#
#  id               :integer          not null, primary key
#  address_type     :string(255)
#  street_address_1 :string(255)      not null
#  street_address_2 :string(255)
#  city             :string(255)      not null
#  state            :string(255)      not null
#  zip_code         :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#  mailing_name     :string(255)      not null
#  latitude         :float
#  longitude        :float
#  user_id          :integer          not null
#

class Address < ActiveRecord::Base
  extend ForeignKeyValidity

  belongs_to :user

  validates :user_id, presence: true, numericality: { only_integer: true }
  validate :validates_user_id_by_inclusion

  validates :mailing_name, presence: true, format: { with: /\A[-\ .\'\w]+\Z/,
    message: "We're sorry, our system can't handle that mailing name." }

  validates :street_address_1, presence: true, format: { with: /\A[-\ .\'\w]+\Z/,
    message: "We're sorry, our system can't handle that street address."}

  validates :street_address_2, allow_blank: true, format: { with: /\A[-\ .\'\w]+\Z/,
    message:  "We're sorry, our system can't handle that street address." }

  validates :address_type, allow_blank: true, format: { with: /\A[\w]+\Z/,
    message: "We're sorry, our system can't handle that address type."}

  validates :city, presence: true, format: { with: /\A[-\ .\'\w]+\Z/,
    message: "We're sorry, our system can't handle that city name."}

  validates :state, presence: true, format: { with: /\A[A-Za-z]{2}\Z/,
    message: "The state must be in abbreviated form (two letters)."}

  validates :zip_code, presence: true, length: { is: 5 }, numericality: {only_integer: true}


  def validates_user_id_by_inclusion
    unless Address.valid_user?(user_id)
      error_msg = "is not a valid user id"
      errors.add(:user_id, error_msg)
    end
  end

  geocoded_by :full_street_address
  after_validation :geocode

  def full_street_address
    [street_address_1, street_address_2, city, state, zip_code].compact.join(',')
  end
end
