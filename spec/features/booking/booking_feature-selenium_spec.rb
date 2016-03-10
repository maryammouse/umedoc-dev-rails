require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include PromotionsHelper

feature "booking-selenium", focus:true do

  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'

  scenario "When the user signs up after being redirected from\
  booking, they are taken to the prefilled booking page and can\
  see the Stripe button", driver: :selenium do
    oncall_time = FactoryGirl.create(
        :oncall_time,
        timerange:(Time.now.round_off(5.minutes) - 1.hours)...
            (Time.now.round_off(5.minutes) + 1.hours)) # next_available
    lead_time = 30.minutes
    visit_duration = 30.minutes
    otol = FactoryGirl.create(
        :oncall_times_online_location,
        oncall_time_id: oncall_time.id)


    expected_start_time = (Time.now.round_off(5.minutes) +
        lead_time).
        strftime('%m-%d-%y %l:%M %p %Z')
    expected_end_time = (Time.now.round_off(5.minutes) +
        lead_time +  visit_duration).
        strftime('%m-%d-%y %l:%M %p %Z')

    day_of_week = (Time.now + lead_time).wday

    location_list = []
    oncall_time.online_locations.each do |n|
      location_list << n.state_name
    end
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: expected_start_time }).
        find_by(day_of_week: Time.now.wday).online_visit_fee
    # cost = day_of_week * 10 + 100
    StripeCustomer.destroy_all

    VCR.use_cassette 'booking_sign_up' do

      Authy.api_key = pro_key
      Authy.api_uri = pro_uri

      visit('/')
      find_button("Book Now", match: :first).native.send_keys(:return)
      find_link("Continue").native.send_keys(:return)

      sleep 1
      fill_in "temporary_user[username]", with: 'test@test.com'
      fill_in "temporary_user[cellphone]", with: '3108040264'

      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri

      sleep 2
      fill_in "verification[token]", with: '0000000'

      find('#TokenContinue').click

      fill_in "user[firstname]", with: 'Maryam'
      fill_in "user[lastname]", with: 'Test'
      fill_in "user[password]", with: 'testword'
      fill_in "user[password_confirmation]", with: 'testword'
      select "female", :from => "user[gender]"
      select "January", :from => "user[dob(2i)]"
      select "1", :from => "user[dob(3i)]"
      select "1996", :from => "user[dob(1i)]"

      find("#SignupSubmit").click

      expect(page).to have_content 'Booking'
      expect(page).to have_content expected_start_time
      expect(page).to have_content expected_end_time
      expect(page).to have_content distance_of_time_in_words(visit_duration)
      expect(page).to have_content cost

      expect(page).to have_content "Visit Details"
      expect(page).to have_content "Fee"
      expect(page).to have_content "Doctor"

    end

    Authy.api_key = test_key
    Authy.api_uri = test_uri

  end

  scenario "When a user books a visit for the first time, they use the Stripe Checkout", :driver => :selenium do
    patient = FactoryGirl.create(:patient)
    StripeCustomer.destroy_all
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time_with_online_and_office_location, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    #otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)

    visit('/')
    #find_button("Book Now", match: :first).click
    find('#BookOffice', match: :first).native.send_keys(:return)

    sleep(1)
    stripe_button = find(:css,'button.stripe-button-el')
    stripe_button.native.send_keys(:return)

    within_frame('stripe_checkout_app') {
      fill_in 'email', with: 'testes@lol.com'
      fill_in 'card_number', with: '4242'
      find_field('card_number').native.send_keys('4242')
      find_field('card_number').native.send_keys('4242')
      find_field('card_number').native.send_keys('4242')
      find('#cc-exp').click
      execute_script(%Q{ $('input#cc-exp').val('09/16'); })
      find('#cc-csc').click
      execute_script(%Q{ $('input#cc-csc').val('940'); })
      execute_script(%Q{ $('input#billing-zip').val('94025'); })
      find('#submitButton').click
    }


    expect(page).not_to have_button 'Checkout'
    #expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Booking Visit Details Please confirm that these details are correct.'
    #expect(page).to have_content 'Visits Notice Board'
    #expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content oncall_time.office_locations.first.street_address_1
  end


end