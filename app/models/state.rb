# == Schema Information
#
# Table name: states
#
#  name       :string(255)      not null
#  country_id :string(3)        not null
#  iso        :string(16)       not null
#

class State < ActiveRecord::Base
end
