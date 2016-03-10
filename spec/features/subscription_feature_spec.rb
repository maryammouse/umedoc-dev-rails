require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include PromotionsHelper

feature "subscription", focus:true do

  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'


  scenario "visiting the subscription front page works if you have the right cookie" do
    plan = Stripe::Plan.retrieve("sds", 'sk_test_UBU41fIJLzcf9nGaAymge3hQ')
    page.set_rack_session(plan: {id: plan.id, doctor_key: 'sk_test_UBU41fIJLzcf9nGaAymge3hQ' } )
    visit('/subscribe/new')

    expect(page).to have_content plan.name
  end

  scenario "without a cookie, it redirects you away." do
    visit('/subscribe/new')
    expect(page).to have_content "You haven't chosen a plan to subscribe to!"
  end


  scenario "only the address form, plan details and checkout show for current customers" do
    p = FactoryGirl.create(:patient)
    plan = Stripe::Plan.retrieve("sds", 'sk_test_UBU41fIJLzcf9nGaAymge3hQ')
    page.set_rack_session(user_id: p.user.id)
    page.set_rack_session(plan: {id: plan.id, doctor_key: 'sk_test_UBU41fIJLzcf9nGaAymge3hQ' } )
    visit('/subscribe/new')

    expect(page).to have_content 'Address'

    expect(page).to have_content plan.name
    expect(page).to have_content number_to_currency(plan.amount / 100) + ' per month!'
    expect(page).to have_content 'Street Address 1'
    expect(page).to have_content 'Street Address 2'
    expect(page).to have_content 'City'
    expect(page).to have_content 'State'
    expect(page).to have_content 'Zip Code'
    expect(page).to have_content 'Select an address'
    expect(page).to have_button 'Subscribe'
  end

  scenario "For current customers, when they fill out the form and checkout, they are subscribed to the plan" do
    p = FactoryGirl.create(:patient)
    plan = FactoryGirl.create(:plan)
    StripeSeller.first.destroy

    page.set_rack_session(user_id: p.user.id)
    page.set_rack_session(plan: {id: plan.plan_id, doctor_key: plan.stripe_seller.access_token} )
    visit('/subscribe/new')

    expect(page).to have_content 'Address'
    expect(page).to have_button 'Subscribe'
    stripe_plan = Stripe::Plan.retrieve("sds", plan.stripe_seller.access_token)

    fill_in "stripe[street_address_1]", with: '100 Avenaire Road'
    fill_in "stripe[city]", with: 'Los Angeles'
    fill_in "stripe[zip_code]", with: '90034'
    select "California", from: "stripe[state]"

    find('#SubscribeSubmit').click

    expect(page).to have_content 'You have been subscribed to the ' + stripe_plan.name
    p.reload
    expect(p.user.addresses.first).not_to equal(nil)
    expect(p.user.stripe_customer.subscription).not_to equal(nil)
    expect(page).to have_content 'An email receipt has been sent to your address'
  end

  scenario "If a patient already has an address on file, they can select it and use it to subscribe" do
    p = FactoryGirl.create(:patient)
    FactoryGirl.create(:address, user_id: p.user.id)
    plan = FactoryGirl.create(:plan)
    StripeSeller.first.destroy

    page.set_rack_session(user_id: p.user.id)
    page.set_rack_session(plan: {id: plan.plan_id, doctor_key: plan.stripe_seller.access_token} )
    visit('/subscribe/new')

    expect(page).to have_content 'Address'
    expect(page).to have_button 'Subscribe'
    stripe_plan = Stripe::Plan.retrieve("sds", plan.stripe_seller.access_token)

    select "3261 Sunset Avenue, Apt 101, Menlo Park, CA 94025", from: "stripe[address]"
    find('#SubscribeSubmit').click

    expect(page).to have_content 'You have been subscribed to the ' + stripe_plan.name
    p.reload
    expect(p.user.addresses.first).not_to equal(nil)
    expect(p.user.stripe_customer.subscription).not_to equal(nil)
    expect(page).to have_content 'An email receipt has been sent to your address'
    expect(page).to have_content 'Your Current Subscription'

  end


  scenario "There is a page to view your subscription status" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    p = FactoryGirl.create(:patient, user_id: user.id)
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save

    page.set_rack_session(user_id: p.user.id)

    visit('/subscribe/edit')
    expect(page).to have_content 'The Simple Doctor Service with Dr. ' + plan.stripe_seller.user.lastname
    expect(page).to have_content 'Payment details'
    expect(page).to have_content 'Update details'
    expect(page).to have_content 'Message doctor'
    expect(page).to have_content "View doctor profile"

  end

  scenario "Canceling the subscription with the button gives an alert first" do
    address = FactoryGirl.create(:address)
    plan = FactoryGirl.create(:plan)
    user = address.user
    p = FactoryGirl.create(:patient, user_id: user.id)
    subscription = FactoryGirl.build(:subscription, stripe_customer_id: user.stripe_customer.id, address_id: address.id,
                                     plan_id: plan.id)
    subscription.save

    page.set_rack_session(user_id: p.user.id)

    visit('/subscribe/edit')

  end



  scenario "A doctor can view the simple doctor service 'signup'" do
    doc = FactoryGirl.create(:doctor)
    page.set_rack_session(user_id: doc.user.id)

    visit('/sds/join')

    expect(page).to have_content 'Offer Your Patients the Simple Doctor Service'
    expect(page).to have_content 'How much will you charge every month?'
    expect(page).to have_content 'Umedoc takes 10%'
    expect(page).to have_content 'Patients who are not subscribed can still book visits with you.'

  end

  scenario "A doctor can make a plan via our site" do
    doc = FactoryGirl.create(:doctor)
    begin
      plan = Stripe::Plan.retrieve("sds", doc.user.stripe_seller.access_token)
      plan.delete

    rescue => e

    end
    page.set_rack_session(user_id: doc.user.id)

    visit('/sds/join')

    expect(page).to have_content 'Offer Your Patients the Simple Doctor Service'
    expect(page).to have_content 'How much will you charge every month?'
    expect(page).to have_content 'Umedoc takes 10%'
    expect(page).to have_content 'Patients who are not subscribed can still book visits with you.'

    fill_in 'plan[amount]', with: '60'
    find('#JoinSubmit').click

    expect(page).to have_content 'You are now a part of the Simple Doctor Service!'
    expect(page).to have_content 'Here you can view your subscribers'


    new_plan = Stripe::Plan.retrieve(doc.user.stripe_seller.plan.plan_id, doc.user.stripe_seller.access_token)
    expect(new_plan.name).to eq('Simple Doctor Service')

  end
  scenario "If there is a stripe error it is handled correctly doctor" do
    doc = FactoryGirl.create(:doctor)
    page.set_rack_session(user_id: doc.user.id)

    visit('/sds/join')

    expect(page).to have_content 'Offer Your Patients the Simple Doctor Service'
    expect(page).to have_content 'How much will you charge every month?'
    expect(page).to have_content 'Umedoc takes 10%'
    expect(page).to have_content 'Patients who are not subscribed can still book visits with you.'

    fill_in 'plan[amount]', with: '60'
    find('#JoinSubmit').click

    expect(page).to have_content 'The plan could not be created.'
  end

end
