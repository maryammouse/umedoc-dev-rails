require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper

feature "visits", focus:true do


  scenario "When a user checks out, they are taken to an 'upcoming visit' notice board page" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now.in_time_zone('US/Pacific') - 2.hours)...
                                     (Time.now.in_time_zone('US/Pacific') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)

    visit('/')
    find_button("Book Now", match: :first).click
    
    find_button("Checkout").click

    expect(page).not_to have_button 'Checkout'
    expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content otof.office_location.street_address_1
  end

  scenario "When a user has an upcoming offline visit, they can see all information regarding that visit" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    patient.user.password = 'testword'
    patient.user.save!
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit = FactoryGirl.create(:visit_stubbed, patient_id: patient.id )
    real_visit = Visit.find_by(id: visit.id)
    vof = FactoryGirl.create(:visits_office_location, visit_id: visit.id)

    visit('/visits')

    expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content real_visit.timerange.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content real_visit.timerange.end.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content visit.office_location.street_address_1
    expect(page).to have_content visit.office_location.street_address_2
    expect(page).to have_content visit.office_location.city
    expect(page).to have_content visit.office_location.state
    expect(page).to have_content visit.office_location.zip_code
  end

  scenario "When a user has a past offline visit, they can see all information regarding that visit in the 'last visit' area" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    patient.user.password = 'testword'
    patient.user.save!
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit = FactoryGirl.create(:visit_stubbed, patient_id: patient.id )
    real_visit = Visit.find_by(id: visit.id)
    vof = FactoryGirl.create(:visits_office_location, visit_id: visit.id)

    Timecop.freeze(Time.now + 5.hours) do
      visit('/visits')

      expect(page).not_to have_content 'You have an upcoming visit!'
      expect(page).to have_content 'Visits Notice Board'
      expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
      expect(page).to have_content 'Your last visit was a'
      expect(page).to have_content visit.oncall_time.doctor.user.firstname
      expect(page).to have_content visit.oncall_time.doctor.user.lastname
      expect(page).to have_content real_visit.timerange.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y at %H:%M')
      expect(page).to have_content distance_of_time_in_words(real_visit.timerange.end, real_visit.timerange.begin, include_seconds: true)
    end
  end

  scenario "A patient can view all the upcoming visits they have" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    patient.user.password = 'testword'
    patient.user.save!
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit01 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 10.minutes)...(Time.now + 16.minutes), patient_id: patient.id)
    visit02 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 20.minutes)...(Time.now + 26.minutes), patient_id: patient.id).reload
    visit03 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 30.minutes)...(Time.now + 36.minutes), patient_id: patient.id)
    vof01 = FactoryGirl.create(:visits_office_location, visit_id: visit01.id)
    vof02 = FactoryGirl.create(:visits_office_location, visit_id: visit02.id)
    vof03 = FactoryGirl.create(:visits_office_location, visit_id: visit03.id)

    visit('/visits')

    expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content visit02.timerange.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content 'Future Visits'


  end

  scenario "A patient can view all the past visits they had" do
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    patient.user.password = 'testword'
    patient.user.save!
    visit('/login')
    fill_in "session[username]", with: patient.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit01 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 10.minutes)...(Time.now + 16.minutes), patient_id: patient.id)
    visit02 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 20.minutes)...(Time.now + 26.minutes), patient_id: patient.id).reload
    visit03 = FactoryGirl.create(:visit_stubbed, timerange: (Time.now + 30.minutes)...(Time.now + 36.minutes), patient_id: patient.id)
    vof01 = FactoryGirl.create(:visits_office_location, visit_id: visit01.id)
    vof02 = FactoryGirl.create(:visits_office_location, visit_id: visit02.id)
    vof03 = FactoryGirl.create(:visits_office_location, visit_id: visit03.id)


    Timecop.freeze(Time.now + 1.day)
    visit('/visits')

    expect(page).to have_content 'Your last visit'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content visit02.timerange.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content 'Past Visits'


  end

  scenario "A doctor can view all the past visits they had" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oc = FactoryGirl.create(:oncall_time, doctor_id: doctor.id )
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    visit01 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                 timerange: (Time.now + 10.minutes)...(Time.now + 16.minutes), oncall_time_id: oc.id)
    customer02 = FactoryGirl.create(:stripe_customer_with_card)
    patient02 = FactoryGirl.create(:patient, user_id: customer02.user.id)
    visit02 = FactoryGirl.create(:visit_stubbed, patient_id: patient02.id,
                                 timerange: (Time.now + 20.minutes)...(Time.now + 26.minutes), oncall_time_id: oc.id).reload
    customer03 = FactoryGirl.create(:stripe_customer_with_card)
    patient03 = FactoryGirl.create(:patient, user_id: customer03.user.id)
    visit03 = FactoryGirl.create(:visit_stubbed, patient_id: patient03.id,
                                 timerange: (Time.now + 36.minutes)...(Time.now + 55.minutes), oncall_time_id: oc.id)
    vof01 = FactoryGirl.create(:visits_office_location, visit_id: visit01.id)
    vof02 = FactoryGirl.create(:visits_office_location, visit_id: visit02.id)
    vof03 = FactoryGirl.create(:visits_office_location, visit_id: visit03.id)


    Timecop.freeze(Time.now + 1.day)
    visit('/visits')

    expect(page).to have_content 'Your last visit'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content visit02.timerange.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content visit02.patient.user.firstname
    expect(page).to have_content 'Past Visits'


  end

  scenario "A doctor can view all the future visits they have" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!
    visit('/login')
    fill_in "session[username]", with: doctor.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oc = FactoryGirl.create(:oncall_time, doctor_id: doctor.id )
    customer = FactoryGirl.create(:stripe_customer_with_card)
    patient = FactoryGirl.create(:patient, user_id: customer.user.id)
    visit01 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                 timerange: (Time.now + 10.minutes)...(Time.now + 16.minutes), oncall_time_id: oc.id)
    customer02 = FactoryGirl.create(:stripe_customer_with_card)
    patient02 = FactoryGirl.create(:patient, user_id: customer02.user.id)
    visit02 = FactoryGirl.create(:visit_stubbed, patient_id: patient02.id,
                                 timerange: (Time.now + 20.minutes)...(Time.now + 26.minutes), oncall_time_id: oc.id).reload
    visit02.reload
    customer03 = FactoryGirl.create(:stripe_customer_with_card)
    patient03 = FactoryGirl.create(:patient, user_id: customer03.user.id)
    visit03 = FactoryGirl.create(:visit_stubbed, patient_id: patient03.id,
                                 timerange: (Time.now + 30.minutes)...(Time.now + 36.minutes), oncall_time_id: oc.id)
    vof01 = FactoryGirl.create(:visits_office_location, visit_id: visit01.id)
    vof02 = FactoryGirl.create(:visits_office_location, visit_id: visit02.id)
    vof03 = FactoryGirl.create(:visits_office_location, visit_id: visit03.id)


    visit('/visits')

    expect(page).to have_content 'You have an upcoming visit!'
    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'This is where you can check the status of any upcoming visits, whether online or offline'
    expect(page).to have_content visit01.timerange.begin.round_off(5.minutes).
                                     in_time_zone('Pacific Time (US & Canada)').
                                     strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content visit02.timerange.begin.round_off(5.minutes).
                                     in_time_zone('Pacific Time (US & Canada)').
                                     strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content visit02.patient.user.firstname
    expect(page).to have_content 'Future Visits'


  end



end
