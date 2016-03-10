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

require 'rails_helper'

RSpec.describe StripeSeller, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
