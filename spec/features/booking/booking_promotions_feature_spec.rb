require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include PromotionsHelper

feature "booking+promotions", focus:true do

  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'


  scenario "On the home page, if you have redeemed a code there is a promo code menu
     with a promo code selected." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    visit('/')

    expect(page).to have_content 'Currently applied promotion'
    expect(page).to have_content 'Free visits and shit'
    expect(page).to have_content number_to_currency(cost) +
                                     ' ' +
                                     Promotion.discounted_fee(promotion, cost)

  end

  scenario "On the home page, if you have redeemed several codes there is a promo code menu
     with a promo code selected." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    promotion02 = FactoryGirl.create(:promotion)

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    visit('/')

    expect(page).to have_content 'Currently applied promotion'
    expect(page).to have_content 'Free visits and shit'
    expect(page).to have_content number_to_currency(cost) +
                                     ' ' +
                                     Promotion.discounted_fee(promotion, cost)

  end

  scenario "On the home page, changing your selected promo code changes the discounts shown on the page.",
           :driver => :poltergeist do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time_with_office_location)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    promotion02 = FactoryGirl.create(:promotion, name: 'Magical Mayhem',
                                     doctor_id: oncall_time.doctor.id)

    cost02 = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                         { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion02.id,
                                                  uses_counter: 0)

    visit('/')

    select(promotion02.promo_code + ' | ' + promotion_name(promotion02), from: 'promo_code')


    expect(page).to have_content 'Currently applied promotion'
    expect(page).to have_select 'promo_code', selected: promotion02.promo_code + " | Magical Mayhem"
    expect(page).to have_content number_to_currency(cost02) +
                                     ' ' +
                                     Promotion.discounted_fee(promotion02, cost02)

  end

  scenario "On the booking page, if you have redeemed a code there is a promo code menu
     with a promo code selected." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    visit('/')
    find_button("Book Now", match: :first).click

    expect(page).to have_selector('div#promo-codes')
    expect(page).to have_content '(currently applied)'
    expect(page).to have_content('To add a new coupon, click here.')

  end

  scenario "On the booking page, if you have not yet redeemed a code there is no promo code menu
  and only a link to redeem code." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    # cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).find_by(day_of_week: 0).fee

    lead_time = 30.minutes
    day_of_week = (Time.now.in_time_zone('US/Pacific') +
        lead_time).wday
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee

    discounted = cost -  (cost * (promotion.discount / 100).to_f)

    visit('/')
    find_button("Book Now", match: :first).click

    expect(page).not_to have_button('Apply')
    expect(page).to have_content('To add a new coupon, click here.')

  end

  scenario "When you click a promo code's apply button, it is successfully applied to your visit." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    promotion02 = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    patients_promotion02 = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion02.id,
                                                    uses_counter: 0)

    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).click

    id_piece = '#' + promotion02.promo_code
    find(id_piece).click

    expect(page).to have_content 'Your code was successfully applied!'
    expect(page).to have_content 'You have a ' + discount_description(promotion02.discount_type, promotion02.discount) +
                                     ' discount on your visit!'
    expect(page).to have_content 'Fee: ' +
                                     number_to_currency(cost) +
                                     ' ' +
                                     Promotion.discounted_fee(promotion02, cost)
  end

  scenario "No promo codes show up in the select box if they cannot be used with that visit's doctor"  do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    promotion02 = FactoryGirl.create(:promotion)
    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)
    patients_promotion02 = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion02.id,
                                                    uses_counter: 0)


    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    discounted = cost -  (cost * (promotion.discount / 100).to_f)

    bad_selection = promotion02.promo_code + " | " + promotion_name(promotion02)
    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).click

    expect(page).not_to have_button 'Apply'

  end

  scenario "When you select a 100% discount promo code, you see a special 'free visit' button" do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('Pacific Time (US & Canada)') - 2.hours)...(Time.now.in_time_zone('Pacific Time (US & Canada)') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id, discount: 100,
                                   discount_type: 'percentage')
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M')}).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    discounted = (cost.to_f -  (cost.to_f * (promotion.discount.to_f / 100))).to_f

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).click

    selection = promotion_name(promotion)

    expect(page).to have_content selection
    expect(page).to have_content 'currently applied'

    expect(page).to have_button 'Checkout your Free Visit!'

  end

  scenario "When you click the free visit button, you are taken straight to the visit page with no Stripe involvement" do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time,
                                     timerange:(Time.now.in_time_zone('Pacific Time (US & Canada)') - 2.hours)...
                                         (Time.now.in_time_zone('Pacific Time (US & Canada)') + 2.hours))
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion,
                                   doctor_id: oncall_time.doctor.id,
                                   discount: 100, discount_type: 'percentage')
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    discounted = (cost.to_f -  (cost.to_f * (promotion.discount.to_f / 100))).to_f

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)
    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).click

    selection = promotion_name(promotion)

    expect(page).to have_content selection
    expect(page).to have_content 'currently applied'

    find_button('Checkout your Free Visit!').click

    sleep(2)

    visit = Visit.find_by(oncall_time_id: oncall_time.id)
    expect(page).to have_content 'You have an upcoming visit!'
    expect(visit.fee_paid).to equal(0)



  end


  scenario "When you enter a valid promo code and checkout, the fee you paid was discounted.", :driver => :selenium do
    patient = FactoryGirl.create(:patient)
    StripeCustomer.destroy_all
    page.set_rack_session(user_id: patient.user.id)
    oncall_time = FactoryGirl.create(:oncall_time,
                                     timerange: (Time.now.in_time_zone('Pacific Time (US & Canada)') - 2.hours)...
                                         (Time.now.in_time_zone('Pacific Time (US & Canada)') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location,
                              oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion,
                                   doctor_id: oncall_time.doctor.id,
                                   discount_type: 'percentage')
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                       { start_time: Time.now.strftime('%H:%M') }).
        find_by(day_of_week: Time.now.wday).office_visit_fee
    discounted = ((cost.to_f -  (cost.to_f * (promotion.discount.to_f / 100.0))) * 100)
    puts discounted
    discounted = discounted.round
    puts discounted



    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)
    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).native.send_keys(:return)


    expect(page).to have_content 'currently applied'

    expect(page).to have_content 'Fee: ' +
                                     number_to_currency(cost) +
                                     ' ' +
                                     Promotion.discounted_fee(promotion, cost)


    expect(page).not_to have_button 'Checkout your Free Visit!'

    stripe_button = find(:css,'button.stripe-button-el')
    stripe_button.click()
    within_frame('stripe_checkout_app') {
      fill_in 'email', with: 'testes@lol.com'
      sleep(0.5)
      find_field('card_number').native.send_keys('4242')
      sleep(0.5)
      find_field('card_number').native.send_keys('4242')
      sleep(0.5)
      find_field('card_number').native.send_keys('4242')
      sleep(0.5)
      find_field('card_number').native.send_keys('4242')
      sleep(0.5)
      find('#cc-exp').click
      execute_script(%Q{ $('input#cc-exp').val('09/16'); })
      sleep(0.5)
      find('#cc-csc').click
      execute_script(%Q{ $('input#cc-csc').val('940'); })
      sleep(0.5)
      execute_script(%Q{ $('input#billing-zip').val('94025'); })
      find('#submitButton').click
    }



    sleep(15)


    visit = Visit.find_by(oncall_time_id: oncall_time.id)


    expect(page).to have_content 'You have an upcoming visit!'
    puts visit.fee_paid
    expect(visit.fee_paid).to eq discounted

  end


  scenario "When a promo code has been applied and you try to book another visit for which it is invalid, the code is cleared." do
    patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: patient.user.id)

    oncall_time = FactoryGirl.create(:oncall_time_with_office_location, timerange:(Time.now.in_time_zone('Pacific Time (US & Canada)') - 2.hours)...(Time.now.in_time_zone('Pacific Time (US & Canada)') + 2.hours)) # next_available
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    FactoryGirl.create(:oncall_time_with_online_location)

    patients_promotion = PatientsPromotion.create(patient_id: patient.id, promotion_id: promotion.id,
                                                  uses_counter: 0)

    sleep(5)
    visit('/')
    sleep(1)
    find("#BookOffice", match: :first).click

    selection = promotion_name(promotion)


    expect(page).to have_content selection
    expect(page).to have_content 'currently applied'

    visit('/')
    find("#BookOnline", match: :first).click

    sleep(2)


    expect(page).not_to have_content "You have a " + promotion.discount.to_s + "% discount on your visit!"
    expect(page).not_to have_button 'Checkout your Free Visit!'
    expect(page).to have_content "We're sorry, the code that was applied is invalid for this visit and has been removed."
  end
  end
