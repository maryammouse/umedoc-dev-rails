# == Schema Information
#
# Table name: phones
#
#  id         :integer          not null, primary key
#  number     :string(255)      not null
#  phone_type :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer          not null
#

class Phone < ActiveRecord::Base
  extend ForeignKeyValidity
  belongs_to :users

  validates :user_id, presence: true, numericality: { only_integer: true }
  validate :validates_user_id_by_inclusion

  validates :number, presence: true, numericality: { only_integer: true },
    length: { is: 10 }
  validates :phone_type, presence: true, inclusion: { in: ['home', 'mobile', 'office', 'other'] }

  def validates_user_id_by_inclusion
    unless Address.valid_user?(user_id)
      error_msg = "is not a valid user id"
      errors.add(:user_id, error_msg)
    end
  end
end
