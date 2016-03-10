# == Schema Information
#
# Table name: patients
#
#  id      :integer          not null, primary key
#  user_id :integer          not null
#

class Patient < ActiveRecord::Base
  extend ForeignKeyValidity
  belongs_to :user
  has_many :visits
  has_many :patients_promotions
  validates :user_id, presence: true, numericality: { only_integer: true }
  validate :user_id_fkey

  def user_id_fkey
    unless Patient.valid_user?(user_id)
      error_msg = "is not a valid user id"
      errors.add(:user_id, error_msg)
    end
  end
end
