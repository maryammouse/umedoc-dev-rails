# == Schema Information
#
# Table name: countries
#
#  name :string(255)
#  iso  :string(2)        not null, primary key
#

FactoryGirl.define do
  factory :country do
    name "MyString"
iso ""
  end

end
