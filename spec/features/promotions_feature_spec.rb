require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include ActionView::Helpers::TextHelper
include PromotionsHelper

feature "promotions", focus:true do
  
  scenario "There is a page where you can add and view promotions" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click


    visit('/promotions')
    expect(page).to have_selector 'h1', text: 'Your Promotions'
    expect(page).to have_content 'Add a Promotion'
    expect(page).to have_content 'Promo Code'
    expect(page).to have_content 'Duration'
    expect(page).to have_content 'The duration is the time range within which patients can redeem your promo code.'
    expect(page).to have_content 'Coupon Expiry Date'
    expect(page).to have_content 'This date can extend beyond the end of the promo duration - in fact, we recommend that it does'
    expect(page).to have_content 'The Status Switches'
    expect(page).to have_content 'Timezone'
    expect(page).to have_content 'Discount'
    expect(page).to have_content 'Status'
  end


  scenario "You can only see the promotions page if logged in as a doctor" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')

    expect(page).to have_content('Promotions')
  end

  scenario "You cannot see the promotions page if logged in as a patient" do
    patient = FactoryGirl.create(:patient)
    patient.user.password = 'testword'
    patient.user.save
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')

    expect(page).not_to have_content('Promotions')
  end


  scenario "When you fill in the create promotion form and submit, a new promotion shows up" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    select '8', from: 'create_expiry_date[month]'
    select '28', from: 'create_expiry_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_expiry_date[year]'
    select 'Percentage (EG: 50% off)', from: 'create[discount_type]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    expect(page).to have_content '50% off!'
    expect(page).to have_content promo.promo_code
    expect(page).to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')
  end

  scenario "When you fill in the create promotion form with invalid data and submit,
     errors are displayed" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select '10', from: 'create_start_date[month]'
    select '31', from: 'create_start_date[day]'
    select '2016', from: 'create_start_date[year]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    select '8', from: 'create_expiry_date[month]'
    select '28', from: 'create_expiry_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_expiry_date[year]'
    select 'Percentage (EG: 50% off)', from: 'create[discount_type]'
    fill_in 'create[discount]', with: '130'
    fill_in 'create[max_uses_per_patient]', with: 'want2hax'
    fill_in 'create[name]', with: "'; delete everything lollolll"

    find('#CreateSubmit').click

    expect(page).to have_content 'The promotion could not be created.'
    expect(page).to have_content "has characters our system can't handle. We're sorry!"
    expect(page).to have_content "is not a number"
    expect(page).to have_content "ends before it starts,"
  end

  scenario "When you make a fixed discount promo and submit, a new promotion shows up correctly" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    select '8', from: 'create_expiry_date[month]'
    select '28', from: 'create_expiry_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_expiry_date[year]'
    select 'Fixed (EG: $50 off)', from: 'create[discount_type]'
    fill_in 'create[discount]', with: '130'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    expect(page).to have_content promotion_name(promo)
    expect(page).not_to have_content '130% off!'
    expect(page).not_to have_content '130%'
    expect(page).to have_content promo.promo_code
    expect(page).to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')
  end


  scenario "If you make a promo code applicable/redeemable and hit 'Save Changes', the promo code is applicable/redeemable." do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    check('promo_applicable[' + promo.id.to_s + ']')

    find('#SwitchSubmit').click

    expect(page).to have_content '50% off!'
    expect(page).to have_content promo.promo_code
    expect(page).to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_checked_field 'promo_applicable[' + promo.id.to_s + ']'

  end

  scenario "If you make a promo code bookable and hit 'Save Changes', the promo code is bookable." do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    check('promo_bookable[' + promo.id.to_s + ']')

    find('#SwitchSubmit').click

    expect(page).to have_content '50% off!'
    expect(page).to have_content promo.promo_code
    expect(page).to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_checked_field 'promo_bookable[' + promo.id.to_s + ']'

  end

  scenario "When you edit a promotion using a form, the details of the promotion are changed" do

  doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    find('#edit-tab').click

    select '50% off! with promo code ' + promo.promo_code, from: 'edit[chosen_promo]'
    sleep(2)
    fill_in 'edit[name]', with: 'The Marvelous Sixties'
    fill_in 'edit[discount]', with: '60'
    select '(GMT-10:00) Hawaii', from: 'edit[timezone]'
    select (Time.now.year + 1), from: 'edit_end_date[year]'
    select '5', from: 'edit_start_date[month]'
    select '15', from: 'edit_start_date[day]'
    select '9', from: 'edit_end_date[month]'
    select '19', from: 'edit_end_date[day]'
    select '2016', from: 'edit_expiry_date[year]'
    select 'Fixed (EG: $50 off)', from: 'edit[discount_type]'
    fill_in 'edit[max_uses_per_patient]', with: '2'

    find('#EditSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    expect(page).to have_content 'The Marvelous Sixties'
    expect(page).to have_content promo.promo_code
    expect(page).to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')

  end
  scenario "When you submit an 'invalid promotion' edit form, an error is displayed" do

    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    find('#edit-tab').click

    select '50% off! with promo code ' + promo.promo_code, from: 'edit[chosen_promo]'
    sleep(2)
    fill_in 'edit[name]', with: 'The M@rvelous Sixties'
    fill_in 'edit[discount]', with: 'haha'
    select '(GMT-10:00) Hawaii', from: 'edit[timezone]'
    select (Time.now.year + 1), from: 'edit_end_date[year]'
    select '5', from: 'edit_start_date[month]'
    select '15', from: 'edit_start_date[day]'
    select '9', from: 'edit_end_date[month]'
    select '19', from: 'edit_end_date[day]'
    select '2016', from: 'edit_expiry_date[year]'
    select 'Fixed (EG: $50 off)', from: 'edit[discount_type]'
    fill_in 'edit[max_uses_per_patient]', with: 'lolno'

    find('#EditSubmit').click


    expect(page).to have_content 'is not a number'
    expect(page).to have_content 'could not be edited'

  end
  scenario "When you submit an edit form with invalid data, an error is displayed" do

    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    find('#edit-tab').click

    find('#EditSubmit').click


    expect(page).to have_content 'The promotion could not be edited.'

  end
  scenario "When you set the discount type as 'percentage' and the value as '130' - an invalid percentage - you receive an error." do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    select 'Percentage (EG: 50% off)', from: 'create[discount_type]'
    fill_in 'create[discount]', with: '130'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)


    expect(page).to have_content "The discount value is invalid for that type of discount"

  end


  scenario "When you click the delete button for a promo, it is deleted", driver: :selenium do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').native.send_keys(:return)

    sleep(1)
    promo = Promotion.find_by(doctor_id: doctor.id)

    find("[name='delete']").native.send_keys(:return)
    page.driver.browser.switch_to.alert.accept



    expect(page).to have_content 'Your promotion has been successfully deleted!'
    expect(page).not_to have_content promo.promo_code
    expect(page).not_to have_content promo.applicable_timerange.begin.strftime('%b %-dth %Y')
    expect(page).not_to have_content promo.applicable_timerange.end.strftime('%b %-dth %Y')
    expect(page).not_to have_content promo.bookable_timerange.end.strftime('%b %-dth %Y')
    #expect(page).to have_checked_field 'promo_applicable[' + promo.id.to_s + ']'

  end

  scenario "You can't visit promotions/apply if you are not a patient" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click


    visit('/promotions/redeem')

    expect(page).to have_content 'Sorry, only logged in patients can view this page!'
  end

  scenario "You can visit promotions/apply if you are a patient" do
    patient = FactoryGirl.create(:patient)
    patient.user.password = 'testword'
    patient.user.save
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click


    visit('/promotions/redeem')

    expect(page).to have_content 'Redeem Your Promo Codes'
  end

  scenario "You can redeem a valid/redeemable/applicable promo code" do
    patient = FactoryGirl.create(:patient)
    patient.user.password = 'testword'
    patient.user.save
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    promo = FactoryGirl.create(:promotion, name: nil)

    visit('/promotions/redeem')

    fill_in "promo_code", with: promo.promo_code

    find("#PromoSubmit").click

    pp = PatientsPromotion.find_by(patient_id: patient.id)

    expect(page).to have_content 'Your code was successfully redeemed!'
    expect(page).to have_content promotion_name(promo)
    expect(page).to have_content 'This coupon comes with ' + pluralize(promo.max_uses_per_patient, 'use')
    expect(page).to have_content 'You have ' +  (promo.max_uses_per_patient - pp.uses_counter).to_s + ' left.'
    expect(page).to have_content 'For use with Dr. ' + promo.doctor.user.firstname + ' ' + promo.doctor.user.lastname +
                                     "'s visits only!"
    expect(page).to have_content 'This coupon will expire on ' + promo.bookable_timerange.end.strftime('%b %-dth %Y %Z')
    expect(page).to have_content promo.promo_code.to_s

  end

  scenario "When redirected from the booking page, there is a button that can take you back and is only there
     if you go straight back" do
    patient = FactoryGirl.create(:patient)
    patient.user.password = 'testword'
    patient.user.save
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('Pacific Time (US & Canada)') - 2.hours)...(Time.now.in_time_zone('Pacific Time (US & Canada)') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)
    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).find_by(day_of_week: 0).fee
    discounted = (cost.to_f -  (cost.to_f * (promotion.discount.to_f / 100))).to_f

    visit('/')
    sleep(1)
    find_button("Book Now", match: :first).click

    selection = promotion.promo_code + " | " + promotion_name(promotion)

    find_link('here').click

    expect(page).to have_link 'Back to Booking'

    find_link('Book a Visit').click

    visit('/promotions/redeem')

    expect(page).not_to have_link 'Back to Booking'

  end

  scenario "When you fill in the create promotion form with invalid data
            in the discount field and submit, the correct error shows up", js: true do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '$@'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    expect(page).to have_content 'Discount is not a number'
  end

  scenario "When you fill in the create promotion form with invalid data in
            the max_uses_per_patient field and submit,
            the correct error shows up", js: true do
    doctor = FactoryGirl .create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in "create[discount]", with: '50'
    fill_in "create[max_uses_per_patient]", with: 'haxxor'

    find('#CreateSubmit').click

    expect(page).to have_content 'Max uses per patient is not a number'
  end

  scenario "When you edit a promotion using a form to include invalid data
            in the discount field and submit, the correct error shows up" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/promotions')
    select '8', from: 'create_end_date[month]'
    select '15', from: 'create_end_date[day]'
    select (Time.now + 1.year).year.to_s, from: 'create_end_date[year]'
    fill_in 'create[discount]', with: '50'
    fill_in 'create[max_uses_per_patient]', with: '1'

    find('#CreateSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    find('#edit-tab').click

    select '50% off! with promo code ' + promo.promo_code, from: 'edit[chosen_promo]'
    sleep(2)
    fill_in 'edit[name]', with: 'pro_h@xx0r_2015'
    fill_in 'edit[discount]', with: 'h@xxor%off'
    select '(GMT-10:00) Hawaii', from: 'edit[timezone]'
    select (Time.now.year + 1), from: 'edit_end_date[year]'
    select '5', from: 'edit_start_date[month]'
    select '15', from: 'edit_start_date[day]'
    select '9', from: 'edit_end_date[month]'
    select '19', from: 'edit_end_date[day]'
    fill_in 'edit[max_uses_per_patient]', with: '2m@ny4u'

    find('#EditSubmit').click

    promo = Promotion.find_by(doctor_id: doctor.id)

    expect(page).to have_content 'The promotion could not be edited.'
  end

end
