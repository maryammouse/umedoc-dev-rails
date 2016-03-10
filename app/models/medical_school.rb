# == Schema Information
#
# Table name: medical_schools
#
#  name        :string(255)      not null
#  city        :string(255)      not null
#  country_iso :string(2)        not null
#

class MedicalSchool < ActiveRecord::Base
end
