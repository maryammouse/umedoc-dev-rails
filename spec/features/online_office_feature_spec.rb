require 'rails_helper'
include ActionView::Helpers::DateHelper



feature "online office", focus:false do

  scenario "User is told they're logged out if they visit page while logged out" do
    visit('/office')
    expect(page).to have_content "You can only view your visit information if you are logged in!"
  end

  scenario "User is NOT redirected from office if logged in" do
    @patient = create(:patient)
    @patient.user.password = "testword"
    @patient.user.save

    visit('/login')
    fill_in 'session[username]', with: @patient.user.username
    fill_in 'session[password]', with: "testword"
    find('#LoginSubmit').click

    visit('/office')
    expect(page).to have_content "The Online Office"
    expect(page).to have_content "You will be asked to enter a code using your phone"
  end

  scenario "Upcoming visit is displayed and no video is shown" do
    @user = create(:user)
    @user.password = "testword"
    @user.save
    @patient = create(:patient, user_id: @user.id )
    page.set_rack_session(user_id: @user.id)
    FactoryGirl.create(:stripe_customer_with_card, user_id: @patient.user.id)
    @upcoming_visit = create(:visit, patient_id: @patient.id,
                               timerange: (Time.now.in_time_zone('US/Pacific') + 15.minutes)..(Time.now.in_time_zone('US/Pacific') + 30.minutes))
    vol = FactoryGirl.create(:visits_online_location, visit_id: @upcoming_visit.id)

    visit('/office')

    expect(page).to have_content "The Online Office"
    expect(page).not_to have_css 'div#myPublisherDiv'
    expect(page).not_to have_css 'div#subscribersDiv'
    expect(page).to have_content "You have an upcoming visit!"
    expect(page).to have_content @upcoming_visit.reload.timerange.begin.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
    expect(page).to have_content @upcoming_visit.reload.timerange.end.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
  end

  scenario "When it is time for doctor's visit, they are taken to an authentication/verify page" do
    @doctor = FactoryGirl.create(:doctor)
    @oncall_time = FactoryGirl.create(:oncall_time_with_online_location, doctor_id: @doctor.id)
    @current_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                                        timerange: (Time.now + 1.minute)..(Time.now + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @current_visit.id)
    page.set_rack_session(user_id: @doctor.user.id)

    Timecop.freeze(Time.now + 15.minutes) do
      visit('/office')

      expect(page).to have_content 'Verify'
      expect(page).to have_content 'before you can enter the office for a visit'
    end
  end

  scenario "When it is time for Doctor's visit and they authenticate, they are redirected to the office and  video is open" do
    @doctor = FactoryGirl.create(:doctor)
    @oncall_time = FactoryGirl.create(:oncall_time_with_online_location, doctor_id: @doctor.id)
    @current_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                                       timerange: (Time.now + 1.minute)..(Time.now + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @current_visit.id)
    page.set_rack_session(user_id: @doctor.user.id)


    Timecop.freeze(Time.now + 15.minutes) do
      visit('/office')
      fill_in "verification[token]", with: '0000000'
      find('#TokenContinue').click

      expect(page).not_to have_content 'You have an upcoming visit!'
      expect(page).to have_css '#chatButton'
      expect(page).to have_css 'div#myPublisherDiv'
      expect(page).to have_css 'div#subscribersDiv'
    end
  end

  scenario "When a doctor has authenticated, they are authenticated for the duration of their visit" do
    @doctor = FactoryGirl.create(:doctor)
    @oncall_time = FactoryGirl.create(:oncall_time_with_online_location, doctor_id: @doctor.id)
    @current_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                                        timerange: (Time.now + 1.minute)..(Time.now + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @current_visit.id)
    page.set_rack_session(user_id: @doctor.user.id)

    Timecop.freeze(Time.now + 15.minutes) do
      visit('/office')
      fill_in "verification[token]", with: '0000000'
      find('#TokenContinue').click

      visit('/')
      visit('/office')

      expect(page).to have_css 'div#myPublisherDiv'
      expect(page).not_to have_content 'You have an upcoming visit!'
      expect(page).to have_css 'div#myPublisherDiv'
      expect(page).to have_css 'div#subscribersDiv'
    end
  end

  scenario "During a visit, the chatbox works and sends messages", driver: :selenium do
    @patient = FactoryGirl.create(:patient)
    @patient.user.password = "testword"
    @patient.user.save
    @oncall_time = FactoryGirl.create(:oncall_time,
                                     timerange: (Time.now -
                                                 60.minutes).
                                                 round_off(5.minutes)...
                                                (Time.now +
                                                60.minutes).
                                                round_off(5.minutes))
    @current_visit = FactoryGirl.build(:visit, patient_id: @patient.id,
                                       timerange: (Time.now - 10.minutes).round_off(5.minutes)...
                                       (Time.now + 30.minutes).round_off(5.minutes),
                                       oncall_time_id: @oncall_time.id)

    @current_visit.save(validate: false)
    vol = FactoryGirl.create(:visits_online_location, visit_id: @current_visit.id)
    page.set_rack_session(user_id: @patient.user.id)
      visit('/office')

      sleep(1)
      find("input[id$='chatBody']").set "Magic and Mayhem\n"
      sleep(8)
      find("input[id$='chatBody']").native.send_keys(:enter)
      sleep(1)
      #native.send_keys(:enter)


    body = page.find('body')
    body.native.send_keys(:command, 't')
    visit('/office')
    sleep(5)

      expect(page).to have_css 'input#chatBody'
      expect(page).not_to have_content 'You have an upcoming visit!'
      expect(page).to have_css 'div#myPublisherDiv'
      expect(page).to have_css 'div#subscribersDiv'
      expect(page).to have_content 'Magic and Mayhem'
    
    #Timecop.freeze(Time.now + 15.minutes) do
      #visit('/visit')

      #fill_in "verification[token]", with: '0000000'
      #find('#TokenContinue').click

      #visit('/')
      #visit('/visit')

      #find("input[id$='chatBody']").set "Magic and Mayhem"
      #find("input[id$='chatBody']").native.send_keys(:return)

      #expect(page).to have_content 'Magic and Mayhem'
      #expect(page).to have_css 'input#chatBody'
      #expect(page).not_to have_content 'You have an upcoming visit!'
      #expect(page).to have_css 'div#myPublisherDiv'
      #expect(page).to have_css 'div#subscribersDiv'
    #end
  end


  scenario "When a visit has ended and another starts, a doctor must re-authenticate" do
    @doctor = FactoryGirl.create(:doctor)
    @oncall_time = FactoryGirl.create(:oncall_time_with_online_location, doctor_id: @doctor.id)
    @current_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                                        timerange: (Time.now + 1.minute)..(Time.now + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @current_visit.id)
    @visit_after = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                                      timerange: (Time.now + 35.minutes )..(Time.now + 50.minutes)
                                     )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @visit_after.id)
    page.set_rack_session(user_id: @doctor.user.id)

    Timecop.freeze(Time.now + 15.minutes) do
      visit('/office')

      fill_in "verification[token]", with: '0000000'
      find('#TokenContinue').click

    end

    Timecop.freeze(Time.now + 40.minutes ) do
      visit('/office')

      expect(page).to have_content 'Verify'
    end
  end
  scenario "The most recent visit is displayed and no video is shown" do
    @patient = FactoryGirl.create(:patient)
    @past_visit = FactoryGirl.create(:visit, patient_id: @patient.id,
                                       timerange: (Time.now.beginning_of_minute + 1.minute)..(Time.now.beginning_of_minute + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @past_visit.id)
    page.set_rack_session(user_id: @patient.user.id)
    Timecop.freeze(Time.now + 35.minutes) do
      visit('/office')

      expect(page).to have_content "Your last visit ended "
      expect(page).to have_content distance_of_time_in_words(@past_visit.reload.timerange.end, Time.now, include_seconds: true)
    end
  end

  scenario "Both upcoming and recent visits are displayed and no video is shown" do
    @patient = FactoryGirl.create(:patient)
    FactoryGirl.create(:stripe_customer_with_card, user_id: @patient.user.id)
    @past_visit = FactoryGirl.create(:visit, patient_id: @patient.id,
                                       timerange: (Time.now.in_time_zone('US/Pacific').beginning_of_minute + 1.minute)...
                                       (Time.now.beginning_of_minute + 30.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @past_visit.id)
    @upcoming_visit = FactoryGirl.create(:visit, patient_id: @patient.id,
                                       timerange: (Time.now + 50.minutes)..(Time.now + 80.minutes) )
    vol = FactoryGirl.create(:visits_online_location, visit_id: @upcoming_visit.id)
    page.set_rack_session(user_id: @patient.user.id)


    Timecop.freeze(Time.now.beginning_of_minute + 40.minutes) do
      visit('/office')

      expect(page).to have_content "The Online Office"
      expect(page).not_to have_css 'div#myPublisherDiv'
      expect(page).not_to have_css 'div#subscribersDiv'
      expect(page).to have_content "You have an upcoming visit!"
      expect(page).to have_content "Your last visit ended "
      expect(page).to have_content @upcoming_visit.reload.timerange.begin.beginning_of_minute.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
      expect(page).to have_content @upcoming_visit.reload.timerange.end.beginning_of_minute.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
      expect(page).to have_content distance_of_time_in_words(@past_visit.reload.timerange.end.beginning_of_minute, Time.now.in_time_zone('US/Pacific').beginning_of_minute, include_seconds: true)
    end
  end

  scenario "Specific messages are displayed if no visits have ever been booked" do
    @patient = FactoryGirl.create(:patient)
    page.set_rack_session(user_id: @patient.user.id)

    visit('/office')

  expect(page).to have_content "You have no upcoming visits! Book one here"
  expect(page).to have_content "You haven't had a visit yet! Book one here"
  end

  scenario "Let doctors view upcoming/recent visits" do
    Time.zone = 'US/Pacific'
    @oncall_time = create(:oncall_time)
    @patient = FactoryGirl.create(:patient)
    FactoryGirl.create(:stripe_customer_with_card, user_id: @patient.user.id)
    @past_visit = create(:visit, oncall_time_id: @oncall_time.id,
                       timerange: (Time.zone.now + 1.minute)...
                       (Time.zone.now + 31.minutes),
        patient_id: @patient.id)
    vol = FactoryGirl.create(:visits_online_location, visit_id: @past_visit.id)
    @upcoming_visit = create(:visit, oncall_time_id: @oncall_time.id,
                           timerange: (Time.zone.now + 60.minutes)..(Time.zone.now + 90.minutes),
    patient_id: @patient.id)
    vol = FactoryGirl.create(:visits_online_location, visit_id: @upcoming_visit.id)

    page.set_rack_session(user_id: @oncall_time.doctor.user.id)



    Timecop.freeze(Time.zone.now.beginning_of_minute + 40.minutes) do
      visit('/office')

      expect(page).to have_content "The Online Office"
      expect(page).not_to have_css 'div#myPublisherDiv'
      expect(page).not_to have_css 'div#subscribersDiv'
      expect(page).to have_content "You have an upcoming visit!"
      expect(page).to have_content "Your last visit ended "
      expect(page).to have_content distance_of_time_in_words(@past_visit.reload.timerange.end.in_time_zone('US/Pacific').beginning_of_minute,
                                                             Time.zone.now.beginning_of_minute, include_seconds: true)
    expect(page).to have_content @upcoming_visit.reload.timerange.begin.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
    expect(page).to have_content @upcoming_visit.reload.timerange.end.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
    Time.zone = 'UTC'
    end

  end

  scenario "If there is no online_location, the visit does not appear in upcoming/previous/current visit" do
    Time.zone = 'US/Pacific'
    @oncall_time = create(:oncall_time)
    @patient = FactoryGirl.create(:patient)
    FactoryGirl.create(:stripe_customer_with_card, user_id: @patient.user.id)
    @past_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                       timerange: (Time.zone.now. + 1.minute)...
                       (Time.zone.now + 31.minutes),
    patient_id: @patient.id)
    @upcoming_visit = FactoryGirl.create(:visit, oncall_time_id: @oncall_time.id,
                           timerange: (Time.zone.now + 60.minutes)..(Time.zone.now + 90.minutes),
    patient_id: @patient.id)

    page.set_rack_session(user_id: @oncall_time.doctor.user.id)



    Timecop.freeze(Time.zone.now.beginning_of_minute + 40.minutes) do
      visit('/office')

      expect(page).to have_content "The Online Office"
      expect(page).not_to have_css 'div#myPublisherDiv'
      expect(page).not_to have_css 'div#subscribersDiv'
      expect(page).not_to have_content "You have an upcoming visit!"
      expect(page).not_to have_content "Your last visit ended "
      expect(page).not_to have_content distance_of_time_in_words(@past_visit.reload.timerange.end.beginning_of_minute.in_time_zone('US/Pacific'),
                                                             Time.now.in_time_zone('US/Pacific').beginning_of_minute, include_seconds: true)
    expect(page).not_to have_content @upcoming_visit.reload.timerange.begin.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
    expect(page).not_to have_content @upcoming_visit.reload.timerange.end.in_time_zone('US/Pacific').strftime('%A %b-%d-%Y %H:%M')
    Time.zone = 'UTC'
    end

  end

end

