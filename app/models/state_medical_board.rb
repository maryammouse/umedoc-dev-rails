# == Schema Information
#
# Table name: state_medical_boards
#
#  name    :string(255)      not null
#  state   :string(2)        not null
#  country :string(3)        not null
#  id      :integer          not null, primary key
#

class StateMedicalBoard < ActiveRecord::Base
  has_many :medical_licenses, inverse_of: :state_medical_board
  has_many :temporary_credential
end
