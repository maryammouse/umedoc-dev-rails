# == Schema Information
#
# Table name: countries
#
#  name :string(255)
#  iso  :string(2)        not null, primary key
#

class Country < ActiveRecord::Base
end
