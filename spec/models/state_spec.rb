# == Schema Information
#
# Table name: states
#
#  name       :string(255)      not null
#  country_id :string(3)        not null
#  iso        :string(16)       not null
#

require 'rails_helper'

RSpec.describe State, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
