# == Schema Information
#
# Table name: states
#
#  name       :string(255)      not null
#  country_id :string(3)        not null
#  iso        :string(16)       not null
#

FactoryGirl.define do
  factory :state do
    country_iso nil
name "MyString"
iso "MyString"
  end

end
