require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include PromotionsHelper

feature "booking", focus:true do


  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'



  scenario "When you click book now for a visit,
  you are taken to a prefilled booking page IF NOT LOGGED IN" do
    oncall_time = FactoryGirl.create(
      :oncall_time,
       timerange:(Time.now.round_off(5.minutes) - 1.hours)...
                 (Time.now.round_off(5.minutes) + 1.hour + 5.minute))
    lead_time = 30.minutes
    visit_duration = 30.minutes
    otol = FactoryGirl.create(
      :oncall_times_online_location,
      oncall_time_id: oncall_time.id)

    visit('/')

    expected_start_time = (Time.now.round_off(5.minutes) +
                           lead_time).in_time_zone('US/Pacific').
                           strftime('%m-%d-%y %l:%M %p %Z')
    expected_end_time = (Time.now.round_off(5.minutes).
                         in_time_zone('US/Pacific') +
                         lead_time +  visit_duration).
                         strftime('%m-%d-%y %l:%M %p %Z')

    day_of_week = (Time.now.in_time_zone('US/Pacific') +
                   lead_time).wday

    location_list = []
    oncall_time.online_locations.each do |n|
      location_list << n.state_name
      end

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: expected_start_time }).
        find_by(day_of_week: Time.now.wday).online_visit_fee
    # cost = day_of_week * 10 + 100

    find_button("Book Now",
               match: :first).click



    expect(page).to have_content expected_start_time
    expect(page).to have_content expected_end_time
    expect(page).to have_content distance_of_time_in_words(visit_duration)
    expect(page).to have_content cost

    expect(page).to have_content "Visit Details"
    expect(page).to have_content "Fee"
    expect(page).to have_content "Doctor"

  end



  scenario "If the user is not logged in, they only see\
  a 'Continue' button and no Stripe button" do
    oncall_time = FactoryGirl.create(
      :oncall_time,
      timerange:(Time.now.round_off(5.minutes) - 1.hours)...
      (Time.now.round_off + 1.hours)) # next_available
    otol = FactoryGirl.create(
      :oncall_times_online_location,
      oncall_time_id: oncall_time.id)

    visit('/')

    find_button("Book Now",
               match: :first).click

    expect(page).to have_link "Continue"
  end

  scenario "When the user clicks the continue button,\
  they are taken to the signup page" do
    oncall_time = FactoryGirl.create(
      :oncall_time,
      timerange:(Time.now.round_off(5.minutes) - 1.hours)...
      (Time.now.round_off(5.minutes) + 1.hours)) # next_available
    otol = FactoryGirl.create(
      :oncall_times_online_location,
      oncall_time_id: oncall_time.id)
    visit('/')
    find_button("Book Now", match: :first).click
    find_link("Continue").click

    expect(page).to have_selector 'h1', text: 'Sign Up'
  end



  scenario "If the user IS logged in, when they click Book Now they are taken to the Booking page" do
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now - 1.hours)..(Time.now + 1.minute + 1.hours)) # next_available
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)
    user = create(:patient).user

    page.set_rack_session(user_id: user.id)
    visit('/')
    find_button("Book Now", match: :first).click()

    expect(page).not_to have_content "Continue"
    expect(page).to have_content 'By clicking the button below you agree'
    expect(page).to have_css('form')
  end

  scenario "If the user has already used Stripe with us before, they see an alternate quick-pay button and card info" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now - 1.hours)..(Time.now + 1.minute + 1.hours)) # next_available
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)

    visit('/')
    find_button("Book Now", match: :first).click

    expect(page).not_to have_content "Continue"
    expect(page).to have_button 'Checkout'
    expect(page).to have_content 'Please check these card details are correct'
    expect(page).to have_link 'Update Details'
  end

  scenario "When a user checks out, they are taken to the visit page and have an upcoming visit IF THEY BOOKED AN ONLINE VISIT." do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    page.set_rack_session(user_id: customer.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)

    visit('/')
    find_button("Book Now", match: :first).click

    find_button("Checkout").click

    expect(page).not_to have_button 'Checkout'
    expect(page).to have_content 'You have an upcoming visit!'
  end

  scenario "When a user is booking an office visit, you do see office info and\
  do not see information regarding online stuff on booking page" do
      customer = FactoryGirl.create(:stripe_customer)
      FactoryGirl.create(:patient, user_id: customer.user.id )

      page.set_rack_session(user_id: customer.user.id)
      oncall_time = FactoryGirl.create(
        :oncall_time_with_online_and_office_location,
         timerange:(Time.now.round_off(5.minutes).
                    in_time_zone('US/Pacific') - 2.hours)...
         (Time.now.round_off(5.minutes).
          in_time_zone('US/Pacific') + 2.hours)) # next_available
#      otof = FactoryGirl.create(
        #:oncall_times_office_location,
        #oncall_time_id: oncall_time.id)

      visit('/')
      find('#BookOffice', match: :first).click


      expect(page).to have_content oncall_time.office_locations.first.street_address_1
      expect(page).to have_content oncall_time.office_locations.first.street_address_2
      expect(page).to have_content oncall_time.office_locations.first.city
      expect(page).to have_content oncall_time.office_locations.first.zip_code
      expect(page).not_to have_content 'When you first enter your online visit'
      expect(page).not_to have_content "you agree that you are in one of the doctor's licensed locations"
      expect(page).not_to have_content "Make sure your browser will work with our online visits!"
      expect(page).not_to have_content "Online Locations"

    end

  scenario "When a user checks out, they are taken to an 'upcoming visit' notice board page" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    page.set_rack_session(user_id: customer.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)

    visit('/')
    #find_button("Book Now", match: :second).click
    find('#BookOffice', match: :first).click

    find_button("Checkout").click

    expect(page).not_to have_button 'Checkout'
    expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content otof.office_location.street_address_1
  end




  scenario "If someone else books the visit in the meantime, you get a proper error" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    page.set_rack_session(user_id: customer.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)

    visit('/')
    #find_button("Book Now", match: :second).click
    find('#BookOffice', match: :first).click

    pt = FactoryGirl.create(:patient)
    sc =  FactoryGirl.create(:stripe_customer_with_card, user_id: pt.user.id)
    FactoryGirl.create(:visit,
                       patient_id: pt.id,
                       oncall_time_id: oncall_time.id, timerange: (Time.now)...(Time.now + 1.hour))
    find_button("Checkout").click

    sleep(5)
    expect(page).to have_button 'Checkout'
    expect(page).to have_content "We're very sorry, this visit is no longer available. Please book another!"

  end



end
