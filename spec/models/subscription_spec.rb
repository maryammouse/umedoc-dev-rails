require 'rails_helper'

RSpec.describe Subscription, type: :model do

  it "sends mail when requested to" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    user.username = 'maryam@umedoc.com'
    user.save
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save

    subscription.send_confirmation


    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end
end

