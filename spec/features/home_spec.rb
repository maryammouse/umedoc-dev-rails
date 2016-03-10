require 'rails_helper'
include ActionView::Helpers::DateHelper

require "rails_helper"

feature "visit_homepage", focus:true do
  scenario "I visit the umedoc website" do 
    visit "/"

    expect(page).to have_xpath("//img[@alt='Umedoc']")
  end

  scenario "I want to know what umedoc does" do
    visit "/"

    expect(page).to have_text("The simple doctor service.")
  end

  scenario "I want to know how umedoc works" do
    visit "/"

    expect(page).to have_text("How it Works")
  end

  scenario "I can see the cheapest online and office visits" do

    FactoryGirl.create(:oncall_time_with_online_and_office_location)
    FactoryGirl.create(:oncall_time_with_online_and_office_location,
                       timerange: (Time.now + 6.hours)...(Time.now + 8.hours) )
    first = OncallTime.first.timerange.begin

    visit('/')
    expect(page).to have_content 'Cheapest Online Visit'
    expect(page).to have_content 'Cheapest Offline Visit (physical office)'
  end

  scenario "I want to book a doctor visit and there is a possible-visit available" do
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now - 1.hour)..(Time.now + 3.hours))
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)
    visit "/"

    expect(page).to have_text("Available Doctors")
    expect(page).to have_text("Time")
    expect(page).to have_text("Duration")
    expect(page).to have_text("Online Locations")
    expect(page).to have_text("Offline Locations(physical office)")
    expect(page).to have_text("Cost")
    expect(page).to have_button("Book Now")

  end

  scenario "I want to book a doctor visit and there is a possible-visit available soon (next_available) (online_visit)" do
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now + 1.hour)..(Time.now + 3.hours))
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)
    visit "/"

    expect(page).to have_text("Available Doctors")
    expect(page).to have_text("Time")
    expect(page).to have_text("Duration")
    expect(page).to have_text("Online Locations")
    expect(page).to have_text("Offline Locations(physical office)")
    expect(page).to have_text("Online Fee")
    expect(page).to have_button("Book Now")

  end


  scenario "I want to log in" do
    visit "/"
    click_on("Log In")

    expect(page).to have_text("Login")
    expect(page).to have_text("Hello! Welcome back to Umedoc.")
  end

  scenario "I am not a registered user and I click the book_now button (online), then I am told I must have an account (online visit)" do
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now - 1.hour)..(Time.now + 1.minute +  1.hours))
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)
    visit "/"
    sleep(1)
    find_button("Book Now", match: :first).click

    expect(page).to have_content "You must be logged in to complete booking."
    expect(page).to have_content "Until booking is completed, your chosen visit may be taken by someone else."
  end

  scenario "there is a free_time available today and the visit times are visible on the homepage" do
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(:oncall_time_with_online_location,
                                     timerange:(Time.now - 1.hour).
                                     round_off(5.minutes)...
                                     (Time.now + 2.hours).
                                     round_off(5.minutes))
    puts FreeTime.available.keys.first.in_time_zone('US/Pacific')
    puts FreeTime.available.keys.first.in_time_zone('US/Pacific').strftime('%l:%M %p')
    puts FreeTime.available.keys.sort.first.in_time_zone('US/Pacific')
    puts FreeTime.available.keys.sort.first.in_time_zone('US/Pacific').strftime('%l:%M %p')

    visit "/"
    expected_start_time = "Today at " + FreeTime.available.keys.first.in_time_zone('US/Pacific').strftime('%l:%M %p')


    expect(page).to have_content(expected_start_time)
  end

  scenario "there is a free_time available tomorrow and they are visible on the homepage" do
    lead_time = 30.minutes
    visit_duration = 30.minutes

    oncall_time = FactoryGirl.create(:oncall_time_with_online_location, timerange:(Time.now + 24.hours)..(Time.now + 25.hours + 1.minute))
    visit "/"
    expected_start_time = FreeTime.next_available.keys.first.in_time_zone('US/Pacific').strftime('%A %b-%-d-%Y')

    expect(page).to have_content(expected_start_time)
  end

  scenario "when a free time is available (as close to now as possible), potential visit details are all displayed" do
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(:oncall_time_with_online_location, timerange:(Time.now - 1.hours)..(Time.now + 3.hours))
    visit "/"

    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    location_list = []
    oncall_time.online_locations.each do |n|
      location_list << n.state_name
    end

    #cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).find_by(day_of_week: 0).fee
    lead_time = 30.minutes
    day_of_week = (Time.now.in_time_zone('US/Pacific') +
                   lead_time).wday
    cost = day_of_week * 10 + 200

    location_list.each do |n|
      expect(page).to have_content n
    end
    expect(page).to have_content(cost)
    expect(page).to have_content(duration)
    expect(page).to have_content("There is no physical office available for this visit.")
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)


  end

  scenario "when there are only free times available after more than half an hour, potential visit details are all displayed" do
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(:oncall_time_with_online_location, timerange:(Time.now + 1.hours)..(Time.now + 3.hours))
    visit "/"

    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now.in_time_zone('US/Pacific') +
                   lead_time).wday

    location_list = []
    oncall_time.online_locations.each do |n|
      location_list << n.state_name
    end

    #cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).find_by(day_of_week: 0).fee

    cost = day_of_week * 10 + 200
    location_list.each do |n|
      expect(page).to have_content n
    end
    expect(page).to have_content(cost)
    expect(page).to have_content(duration)
    expect(page).to have_content("There is no physical office available for this visit.")
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)


  end

  scenario "physical office locations are displayed for oncall_times" do
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(:oncall_time_with_office_location, timerange:(Time.now + 1.hours)..(Time.now + 3.hours))
    visit "/"

    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    location_list = []
    oncall_time.office_locations.each do |n|
      location_list << State.where(country_id: n.country).find_by(iso: n.state).name
    end

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).
        find_by(day_of_week: Date.today.wday).office_visit_fee

    lead_time = 30.minutes
    day_of_week = (Time.now.in_time_zone('US/Pacific') +
                   lead_time).wday

    oncall_time.office_locations.each do |n|
      expect(page).to have_content(n.street_address_1)
      expect(page).to have_content(n.street_address_2)
      expect(page).to have_content(n.city)
      expect(page).to have_content(n.zip_code)
    end

    expect(page).to have_content(cost)
    expect(page).to have_button('Book Now')
    expect(page).to have_content('(This visit is not available online)')
    expect(page).to have_content(duration)
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)
  end

  scenario "physical office locations are displayed for oncall_times with both online and offline locations" do
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now + 1.hours)..(Time.now + 3.hours))
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)
    visit "/"

    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    location_list = []
    oncall_time.office_locations.each do |n|
      location_list << State.where(country_id: n.country).find_by(iso: n.state).name
    end

    oncall_time.online_locations.each do |n|
      location_list << n.state_name
    end

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).
        find_by(day_of_week: Date.today.wday).office_visit_fee


    oncall_time.office_locations.each do |n|
      expect(page).to have_content(n.street_address_1)
      expect(page).to have_content(n.street_address_2)
      expect(page).to have_content(n.city)
      expect(page).to have_content(n.zip_code)
    end

    expect(page).to have_content(cost)
    expect(page).to have_button('Book Now')
    expect(page).to have_content(duration)
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)
    expect(page).to have_content(oncall_time.online_locations.first.state_name)
  end

  scenario "no visit is displayed if online_visit_allowed and office_visit_allowed are both 'not_allowed'" do
    # Setup
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(
      :oncall_time_with_online_and_office_location,
      timerange: (Time.now + 1.hours)...(Time.now + 3.hours))
    oncall_time.fee_rules.each do |fee_rule|
      fee_rule.online_visit_allowed = "not_allowed"
      fee_rule.office_visit_allowed = "not_allowed"
      fee_rule.save
    end

    # Start Test
    visit "/"

    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).
        find_by(day_of_week: Date.today.wday).office_visit_fee

    # Assertions
    oncall_time.office_locations.each do |n|
      expect(page).not_to have_content(n.street_address_1)
      expect(page).not_to have_content(n.city)
      expect(page).not_to have_content(n.zip_code)
    end

    expect(page).not_to have_content(cost)
    expect(page).not_to have_button('Book Now')
    expect(page).not_to have_content(oncall_time.doctor.user.firstname)
    expect(page).not_to have_content(oncall_time.doctor.user.lastname)
    expect(page).not_to have_content(duration)

  end

  scenario "only online visit is displayed if online_visit_allowed='allowed' and office_visit_allowed='not_allowed'" do
    # Setup
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(
      :oncall_time_with_online_and_office_location,
      timerange: (Time.now + 1.hours)...(Time.now + 3.hours))
    oncall_time.fee_rules.each do |fee_rule|
      fee_rule.online_visit_allowed = "allowed"
      fee_rule.office_visit_allowed = "not_allowed"
      fee_rule.save
    end

    # Start Test
    visit "/"


    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).
        find_by(day_of_week: Date.today.wday).online_visit_fee

    # Assertions
    #



    oncall_time.office_locations.each do |n|
      expect(page).not_to have_content(n.street_address_1)
      expect(page).not_to have_content(n.city)
      expect(page).not_to have_content(n.zip_code)
    end

    expect(page).to have_content(cost)
    expect(page).to have_button('Book Now')
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)
    expect(page).to have_content(duration)

  end

  scenario "only office visit is displayed if online_visit_allowed='not_allowed' and office_visit_allowed='allowed'" do
    # Setup
    lead_time = 30.minutes
    visit_duration = 30.minutes
    oncall_time = FactoryGirl.create(
      :oncall_time_with_online_and_office_location,
      timerange: (Time.now + 1.hours)...(Time.now + 3.hours))
    oncall_time.fee_rules.each do |fee_rule|
      fee_rule.online_visit_allowed = "not_allowed"
      fee_rule.office_visit_allowed = "allowed"
      fee_rule.save
    end

    # Start Test
    visit "/"


    expected_start_time = (Time.now + lead_time).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    expected_end_time = (Time.now + lead_time + visit_duration).beginning_of_minute.strftime('%m-%d-%y %H:%M %Z')
    duration =  distance_of_time_in_words((Time.now + lead_time + visit_duration) - (Time.now + lead_time))

    day_of_week = (Time.now + lead_time).wday

    cost = oncall_time.fee_rules.where('time :start_time <@ time_of_day_range', { start_time: '15:00' }).
        find_by(day_of_week: Date.today.wday).office_visit_fee
    state_name = oncall_time.online_locations.first.state_name

    # Assertions
    #



    oncall_time.office_locations.each do |n|
      expect(page).to have_content(n.street_address_1)
      expect(page).to have_content(n.city)
      expect(page).to have_content(n.zip_code)
    end

    expect(page).to have_content(cost)
    expect(page).to have_button('Book Now')
    expect(page).to have_content(oncall_time.doctor.user.firstname)
    expect(page).to have_content(oncall_time.doctor.user.lastname)
    expect(page).to have_content(duration)

    expect(page).not_to have_content(state_name)

  end


end
