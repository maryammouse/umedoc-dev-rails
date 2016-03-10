# == Schema Information
#
# Table name: patients_promotions
#
#  id           :integer          not null, primary key
#  patient_id   :integer          not null
#  promotion_id :integer          not null
#  uses_counter :integer          not null
#

class PatientsPromotion < ActiveRecord::Base
  belongs_to :patient
  belongs_to :promotion
end
