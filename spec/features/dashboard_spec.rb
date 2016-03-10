require 'rspec'
require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::NumberHelper

feature 'dashboard' do


  scenario "When you visit the dashboard AS A VERIFIED DOCTOR, it works" do
    doc = FactoryGirl.create(:doctor)
    doc.user.password = 'testword'
    doc.user.save!

    visit('/login')
    fill_in 'session[username]', with: doc.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')
    expect(page).to have_selector 'h1', text: "Doctor's Dashboard"
  end
  
  scenario "When you visit the dashboard when not logged in, you are redirected" do
    visit('/dashboard')
    expect(page).to have_content 'Only logged in, verified doctors can visit this page!'

  end

  scenario "When you visit the dashboard, AS A PATIENT, you are redirected" do
    patient = FactoryGirl.create(:patient)
    patient.user.password = 'testword'
    patient.user.save!

    visit('/login')
    fill_in 'session[username]', with: patient.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')
    expect(page).to have_content 'Only logged in, verified doctors can visit this page!'

  end

  scenario "If you are an unverified doctor, you are redirected from the dashboard" do
    doc = FactoryGirl.create(:doctor, verification_status: 'not_verified')
    doc.user.password = 'testword'
    doc.user.save!

    visit('/login')
    fill_in 'session[username]', with: doc.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')
    expect(page).to have_content 'Only logged in, verified doctors can visit this page!'
    expect(page).not_to have_selector 'h1', text: "Doctor's Dashboard"

  end

  scenario "When you visit the dashboard, the main sections are present" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')
    expect(page).to have_selector 'h1', text: "Doctor's Dashboard"
    expect(page).to have_content 'Availability'
    expect(page).to have_content 'Fee Schedule'
    expect(page).to have_content 'Add Availability'
    expect(page).to have_content 'Create Fee Schedule'
    expect(page).to have_content 'Date and Time'
    expect(page).to have_content 'Duration'
    expect(page).to have_content 'Locations'

  end

  scenario "When you select two valid availability dates and times and submit, an oncall_time is created" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!


    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    FactoryGirl.create(:medical_license, doctor_id: doctor.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled, doctor_id: doctor.id)
    ol = FactoryGirl.create(:office_location)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    fill_in 'start_datetime', with: Time.now.strftime('%m/%d/%Y %l:%M %p')
    fill_in 'end_datetime', with: (Time.now + 7.days).strftime('%m/%d/%Y %l:%M %p')
    check 'online'
    select '3261 Faraday Hall | ' + ol.zip_code.to_s , from: 'office_locations'
    select fs.name , from: 'fee_schedules'

    find('#AvailabilitySubmit').click

    ot = OncallTime.find_by(doctor_id: doctor.id)

    expect(page).to have_content 'You have successfully submitted your availability!'
    expect(page).to have_content 'Starting from ' + ot.timerange.
                                     begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_content 'and ending on ' + ot.timerange.end.
                                     in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
    expect(page).to have_selector 'b', text: 'Online Office'
    expect(page).to have_content ol.street_address_1
    expect(page).to have_content ol.city
    expect(page).to have_content ol.zip_code
    expect(page).to have_content ot.fee_schedule.name


  end

  scenario "When you make an oncall time bookable, it shows up on the home page" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    FactoryGirl.create(:medical_license, doctor_id: doctor.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled, doctor_id: doctor.id)
    ol = FactoryGirl.create(:office_location)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    fill_in 'start_datetime', with: Time.now.strftime('%m/%d/%Y %l:%M %p')
    fill_in 'end_datetime', with: (Time.now + 7.days).strftime('%m/%d/%Y %l:%M %p')
    check 'online'
    select '3261 Faraday Hall | ' + ol.zip_code.to_s , from: 'office_locations'
    select fs.name , from: 'fee_schedules'

    find('#AvailabilitySubmit').click

    expect(page).to have_content 'You have successfully submitted your availability!'

    ot = OncallTime.find_by(doctor_id: doctor.id)
    otol = OncallTimesOnlineLocation.find_by(oncall_time_id: ot.id)

    check 'oncall_time[' + ot.id.to_s + ']'

    find('#SwitchSubmit').click

    expect(page).to have_checked_field 'oncall_time[' + ot.id.to_s + ']'

    visit('/')
    expect(page).to have_content 'Dr. ' + doctor.user.firstname + ' ' + doctor.user.lastname
    expect(page).to have_content otol.online_location.state_name
    expect(page).to have_content ol.street_address_1


  end

  scenario "You can create fee schedules by filling in a name" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    fill_in 'fee_schedule_name', with: 'My Marvellous Schedule'
    find('#ScheduleSubmit').click

    fs = FeeSchedule.find_by(doctor_id: doctor.id)

    expect(page).to have_content 'Your schedule has been created! Time to add the rules.'
    expect(page).to have_content fs.name
  end

  scenario "You can select a fee_schedule to edit", driver: :poltergeist do

    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    fill_in 'fee_schedule_name', with: 'My Marvellous Schedule'
    find('#ScheduleSubmit').click


    fill_in 'fee_schedule_name', with: 'The Best Schedule Ever'
    find('#ScheduleSubmit').click

    fs = FeeSchedule.where(doctor_id: doctor.id).first


    select fs.name , from: 'fee_schedule_select'


    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name
  end

  scenario "You can click on a time block to edit it", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled_limited, doctor_id: doctor.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    select fs.name , from: 'fee_schedule_select'


    sleep(3)


    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name

    find('.fee_rule', match: :first).click


    expect(page).to have_content('Editing day: Monday')
  end

  scenario "You can submit an edited time block and it will be edited", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled_limited, doctor_id: doctor.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    select fs.name , from: 'fee_schedule_select'

    find('#fee-schedule-tab').click

    sleep(3)

    find('#fee-schedule-tab').click

    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name

    find('.fee_rule', match: :first).click
    expect(page).to have_content('Editing day: Monday')

    sleep(5)

    fill_in 'start_time', with: '00:00'
    fill_in 'end_time', with: '03:00'
    fill_in 'online_fee', with: '120'
    fill_in 'office_fee', with: '250'
    check 'office_visit_allowed'
    check 'online_visit_allowed'

    find('#EditSubmit').click

    sleep(5)

    expect(page).to have_content number_to_currency(120)
    expect(page).to have_content number_to_currency(250)
    expect(page).to have_content '00:00'
    expect(page).to have_content '03:00'
    expect(page).to have_content 'Office visits accepted'
    expect(page).to have_content 'Online visits accepted'

  end
  scenario "You can click on an add button to add a time block", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled_limited, doctor_id: doctor.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    select fs.name , from: 'fee_schedule_select'


    sleep(3)

    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name

    find_button('Add', match: :first).click


    expect(page).to have_content('Adding time block for day: Monday')

  end

  scenario "Submitting a new time block adds it to the fee_schedule", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    fill_in 'fee_schedule_name', with: 'The Best Schedule Ever'
    find('#ScheduleSubmit').click


    fs = FeeSchedule.where(doctor_id: doctor.id).first
    select fs.name , from: 'fee_schedule_select'


    sleep(3)


    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name

    find_button('Add', match: :first).click


    sleep(3)
    expect(page).to have_content('Adding time block for day: Monday')

    fill_in 'start_time', with: '00:00'
    fill_in 'end_time', with: '03:00'
    fill_in 'online_fee', with: '120'
    fill_in 'office_fee', with: '250'
    check 'online_visit_allowed'

    find('#EditSubmit').click

    expect(page).to have_content number_to_currency(120)
    expect(page).to have_content '00:00'
    expect(page).to have_content '03:00'
    expect(page).to have_content 'Online visits accepted'

  end

  scenario "Timeblocks ending at 24:00 display correctly when the start is not 00:00", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    fill_in 'fee_schedule_name', with: 'The Best Schedule Ever'
    find('#ScheduleSubmit').click


    fs = FeeSchedule.where(doctor_id: doctor.id).first
    select fs.name , from: 'fee_schedule_select'


    sleep(3)


    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name

    find_button('Add', match: :first).click


    sleep(3)
    expect(page).to have_content('Adding time block for day: Monday')

    fill_in 'start_time', with: '02:00'
    fill_in 'end_time', with: '24:00'
    fill_in 'online_fee', with: '120'
    fill_in 'office_fee', with: '250'
    check 'online_visit_allowed'

    find('#EditSubmit').click


    visit('/dashboard')




    expect(page).to have_content number_to_currency(120)
    expect(page).not_to have_content number_to_currency(250)
    expect(page).to have_content '02:00'
    expect(page).to have_content '24:00'
    expect(page).to have_content 'Online visits accepted'

  end

  scenario "Timeblocks ending at 24:00 display correctly with start time 00:00", driver: :poltergeist do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)
    fs = FactoryGirl.create(:fee_schedule_prefilled, doctor_id: doctor.id)

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click

    visit('/dashboard')

    find('#fee-schedule-tab').click

    select fs.name , from: 'fee_schedule_select'


    sleep(3)


    expect(page).to have_content 'You have selected ' + fs.name + '! You can now edit it by filling in the days.'
    expect(page).to have_content 'Currently editing: ' + fs.name
    expect(page).to have_content '24:00'
  end

  scenario "Old oncall times are not visible by default" do
    doctor = FactoryGirl.create(:doctor)
    doctor.user.password = 'testword'
    doctor.user.save!

    FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

    ot = FactoryGirl.create(:oncall_time, doctor_id: doctor.id)
    ol = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: ot.id).office_location

    visit('/login')
    fill_in 'session[username]', with: doctor.user.username
    fill_in 'session[password]', with: 'testword'
    find('#LoginSubmit').click


    Timecop.freeze(Time.now + 10.hours) do
      visit('/dashboard')

      expect(page).not_to have_content 'Starting from ' + ot.timerange.
                                       begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
      expect(page).not_to have_content 'and ending on ' + ot.timerange.end.
                                       in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
      expect(page).not_to have_selector 'b', text: 'Online Office'
      end
    end

    scenario "You can view and hide old oncall times by clicking on the 'show/hide' bar", driver: :poltergeist do
      doctor = FactoryGirl.create(:doctor)
      doctor.user.password = 'testword'
      doctor.user.save!

      FactoryGirl.create(:stripe_seller, user_id: doctor.user.id)

      ot = FactoryGirl.create(:oncall_time, doctor_id: doctor.id)
      ot.reload
      ol = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: ot.id).office_location

      visit('/login')
      fill_in 'session[username]', with: doctor.user.username
      fill_in 'session[password]', with: 'testword'
      find('#LoginSubmit').click


      Timecop.travel(Time.now + 10.hours) do
        visit('/dashboard')

        find('#show').click

        sleep(3)

        expect(page).to have_content 'Starting from ' + ot.timerange.
                                             begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
        expect(page).to have_content 'and ending on ' + ot.timerange.end.
                                             in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')

        find('#show').click
        sleep(3)
        expect(page).not_to have_content 'Starting from ' + ot.timerange.
                                         begin.in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
        expect(page).not_to have_content 'and ending on ' + ot.timerange.end.
                                         in_time_zone('Pacific Time (US & Canada)').strftime('%A %b-%d-%Y %H:%M %Z')
      end
    end

end