# == Schema Information
#
# Table name: stripe_customers
#
#  id          :integer          not null, primary key
#  customer_id :string(255)      not null
#  user_id     :integer          not null
#

class StripeCustomer < ActiveRecord::Base
  belongs_to :user
  has_one :subscription
end
