# == Schema Information
#
# Table name: patients_promotions
#
#  id           :integer          not null, primary key
#  patient_id   :integer          not null
#  promotion_id :integer          not null
#  uses_counter :integer          not null
#

require 'rails_helper'

RSpec.describe PatientsPromotion, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
