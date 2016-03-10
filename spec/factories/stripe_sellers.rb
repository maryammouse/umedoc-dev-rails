# == Schema Information
#
# Table name: stripe_sellers
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  access_token           :text             not null
#  scope                  :text             not null
#  livemode               :text             not null
#  refresh_token          :text             not null
#  stripe_user_id         :text             not null
#  stripe_publishable_key :text             not null
#

FactoryGirl.define do
  factory :stripe_seller do
    #association :doctor # we currently don't know how to access
    # the user id via the doctor using rspec associations
    user_id {FactoryGirl.create(:doctor).user.id}
    access_token "sk_test_hLSr46i6XVmC7MM7Y6v55nrw"
    scope 'read_write'
    livemode 'false'
    refresh_token 'rt_5r50Ncxwze0F7UZ2KVWBZE4SqEJUCBzqxQdUZC68QwOFzNhG'
    stripe_user_id 'acct_14tSp4FT1hGiThoB'
    stripe_publishable_key 'pk_test_1iDjcc5ce6bL85KKuIUKLh7E'
  end

end
