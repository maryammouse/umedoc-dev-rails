require 'rails_helper'

describe "subscription_controller", type: :request do

  it "sends mail when invoice payment succeeds" do
    # StripeTester.webhook_url = "http://localhost:3000/subscribe/stripe_webhook"
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save
    subscription.update_column(:status, "canceled")


    @stripe_webhook =  StripeTester.load_template(:invoice_payment_succeeded,
                              {
                                  "data"=>{"object"=>{"lines"=>{"data"=>[{"id" => subscription.subscription_id }]}}}, method: :merge
                              }
    )


    post "/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825", @stripe_webhook.to_json


    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end

  it "makes a subscription active when invoice payment succeeds" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save
    subscription.update_column(:status, "canceled")


    @stripe_webhook = StripeTester.load_template(:invoice_payment_succeeded,
                              {
                                  "data"=>{"object"=>{"lines"=>{"data"=>[{"id" => subscription.subscription_id }]}}}, method: :merge
                              }
    )

    post "/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825", @stripe_webhook.to_json

    subscription.reload


    expect(subscription.status).to eq("active")
  end

  it "makes a subscription canceled when invoice payment fails " do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save


    @stripe_webhook = StripeTester.load_template(:invoice_payment_failed,
                                                 {
                                                     "data"=>{"object"=>{"lines"=>{"data"=>[{"id" => subscription.subscription_id }]}}}, method: :merge
                                                 }
    )


    post "/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825", @stripe_webhook.to_json

    subscription.reload



    expect(subscription.status).to eq("canceled")
    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end

  it "adds a 'deleted' subscription to the archive when a subscription is deleted" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save


    @stripe_webhook = StripeTester.load_template(:customer_subscription_deleted,
                                                 {
                                                     "data"=>{"object"=>{"id"=> subscription.subscription_id }}, method: :merge
                                                 }
    )


    post "/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825", @stripe_webhook.to_json

    subscription.reload

    expect(ArchivedSubscription.all).not_to be_empty
  end

  it "updates a subscription when a subscription is updated" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save


    @stripe_webhook = StripeTester.load_template(:customer_subscription_updated,
                                                 {
                                                     "data"=>{"object"=>{"id": subscription.subscription_id,
                                                                         "status"=> 'past_due'}}, method: :merge
                                                 }
    )

    post "/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825", @stripe_webhook.to_json

    subscription.reload

    expect(subscription.status).to eq 'past_due'
  end


end
