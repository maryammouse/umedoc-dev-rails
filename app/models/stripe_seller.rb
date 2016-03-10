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

class StripeSeller < ActiveRecord::Base
  belongs_to :user
  has_one :plan
end
