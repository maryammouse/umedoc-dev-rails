# == Schema Information
#
# Table name: stripe_customers
#
#  id          :integer          not null, primary key
#  customer_id :string(255)      not null
#  user_id     :integer          not null
#

require 'rails_helper'

RSpec.describe StripeCustomer, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
