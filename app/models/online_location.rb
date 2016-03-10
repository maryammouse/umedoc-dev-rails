# == Schema Information
#
# Table name: online_locations
#
#  state      :string(2)        not null
#  country    :string(2)        not null
#  id         :integer          not null, primary key
#  state_name :text             not null
#

class OnlineLocation < ActiveRecord::Base
  extend ForeignKeyValidity

  has_many :oncall_times_online_locations
  has_many :oncall_times, through: :oncall_times_online_locations
  has_many :visits_online_locations
  has_many :visits, through: :visits_online_locations

  validates :state_name, presence: true, format: { with: /\A[\w\s]+\Z/,
    message: "has invalid characters"}

  validates :country, presence: true, format: { with: /\A[\w\s]+\Z/,
    message: "has invalid characters"}

  validates :state, presence: true, length: {is: 2}

  validates :state, presence: true, format: { with: /\A[\w]+\Z/,
    message: "has invalid characters"}

  validate :validate_state_name_by_inclusion

  def validate_state_name_by_inclusion
    unless OnlineLocation.valid_state?(state_name)
      error_msg = "is not a valid state in our database"
      errors.add(:state_name, error_msg)
    end
  end
end
