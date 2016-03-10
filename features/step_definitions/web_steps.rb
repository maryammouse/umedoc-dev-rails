
Given(/^I want to visit the (?:umedoc )website$/) do
  nil
end

When(/^I visit the website$/) do
  visit('/')
end

Then(/^The title\-bar should say "(.*?)"$/) do |arg1|
  expect(page.title).to eq arg1
end

Then(/^The page should say "(.*?)"$/) do |arg1|
  expect(page).to have_content arg1
end

Given(/^I want to know what umedoc does$/) do
  nil
end


Given(/^I want to know how umedoc works$/) do
  nil
end

Then(/^There should be a link for "(.*?)"$/) do |arg1|
  expect(page).to have_link arg1
end

Given(/^I want to book a doctor visit$/) do
  nil
end

Then(/^I should see the header "(.*?)"$/) do |arg1|
  expect(page).to have_content arg1
end

Then(/^I should see the "(.*?)" the doctors are available$/) do |arg1|
  expect(page).to have_content arg1
end

Then(/^I should see the "(.*?)" of the available appointments$/) do |arg1|
  expect(page).to have_content arg1
end


Then(/^I should see if the visit will be "(.*?)", "(.*?)" or "(.*?)"$/) do |arg1, arg2, arg3|
  expect(page).to have_content arg1 || arg2 || arg3
end

Given(/^I am concerned about cost$/) do
  nil
end

Then(/^I should see the "(.*?)" of each doctor visit$/) do |arg1|
  expect(page).to have_content arg1
end

Then(/^I should see whether the doctor takes "(.*?)"$/) do |arg1|
  expect(page).to have_content arg1
end

Given(/^I might want to see a doctor in person$/) do
  nil
end

Then(/^I should see whether the doctor is "(.*?)", "(.*?)", or "(.*?)"$/) do |arg1, arg2, arg3|
  expect(page).to have_content arg1 || arg2 || arg3
end

Given(/^I want to login$/) do
  nil
end

When(/^I click the login button$/) do
  visit('/')
  find('#Login').click
end

When(/^I fill in the login form and click the submit button$/) do
  visit('/login')
  @patient = FactoryGirl.create(:user)
  fill_in "session[username]", with: @patient.username
  fill_in "session[password]", with: @patient.password
  find('#LoginSubmit').click
end

Given(/^I am logged in and want to logout$/) do
  visit('/login')
  @patient = FactoryGirl.create(:user)
  fill_in "session[username]", with: @patient.username
  fill_in "session[password]", with: @patient.password
  find('#LoginSubmit').click
end

When(/^I click the logout button$/) do
  find('#Logout').click
end

Then(/^I am logged out$/) do
  expect(page).to have_content "You have successfully logged out. See you again soon!"
  expect(page).not_to have_content "Hey there, #{@patient.firstname}!"
end

Given(/^I am logged in and want to close my browser$/) do
  nil
end


Then(/^I see a login error$/) do
  expect(page).to have_content "Oops! That's an invalid email/password combination!"
end

When(/^I close my browser, reopen it, and go to Umedoc$/) do
  nil
end
include ActionView::Helpers::DateHelper
Given(/^I want to see the online office and am logged out$/) do
  nil
end

When(/^I visit the online office$/) do
  visit('/visit')
end

Then(/^I see a logged-out error$/) do
  expect(page).to have_content "You must be logged in"
end

Given(/^I am logged in and have an upcoming visit$/) do
  @doc_user = FactoryGirl.create(:user, id: 1)
  @patient = FactoryGirl.create(:user, id: 2, password: "testword")
  @doctor = FactoryGirl.create(:doctor, id: 1, user_id: 1)
  @upcoming_visit = FactoryGirl.create(:visit, doctor_id: 1, patient_id: 2,
                             start_time: Time.now + 15.minutes,
                             end_time: Time.now + 30.minutes)
  visit('/login')
  fill_in 'session[username]', with: @patient.username
  fill_in 'session[password]', with: "testword"
  find("#LoginSubmit").click
end

When(/^I visit the Visit page$/) do
  visit("/visit")
end


Then(/^The video window is not open$/) do
  expect(page).to have_content "The Online Office"
  expect(page).not_to have_css 'div#myPublisherDiv'
  expect(page).not_to have_css 'div#subscribersDiv'
end

Given(/^I am logged in and it is time for my visit$/) do
  @doc_user = FactoryGirl.create(:user, id: 1)
  @patient = FactoryGirl.create(:user, id: 2, password: "testword")
  @doctor = FactoryGirl.create(:doctor, id: 1, user_id: 1)
  @current_visit = FactoryGirl.create(:visit, doctor_id: 1, patient_id: 2,
                             start_time: Time.now,
                             end_time: Time.now + 15.minutes)
  visit('/login')
  fill_in 'session[username]', with: @patient.username
  fill_in 'session[password]', with: "testword"
  find("#LoginSubmit").click
end

Then(/^The video window is open$/) do
  expect(page).not_to have_content 'You have an upcoming visit!'
  expect(page).to have_css 'div#myPublisherDiv'
  expect(page).to have_css 'div#subscribersDiv'
end


Then(/^I see the upcoming visit$/) do
  expect(page).to have_content "You have an upcoming visit!"
  expect(page).to have_content @upcoming_visit.start_time
end

Given(/^I am logged in and my most recent visit is ended$/) do
  @doc_user = FactoryGirl.create(:user, id: 1)
  @patient = FactoryGirl.create(:user, id: 2, password: "testword")
  @doctor = FactoryGirl.create(:doctor, id: 1, user_id: 1)
  @past_visit = FactoryGirl.create(:visit, doctor_id: 1, patient_id: 2,
                             start_time: Time.now,
                             end_time: Time.now + 1.seconds)
  sleep(2)
  visit('/login')
  fill_in 'session[username]', with: @patient.username
  fill_in 'session[password]', with: "testword"
  find("#LoginSubmit").click
end

Then(/^I see my most recent visit$/) do
  expect(page).to have_content "Your last visit ended "
  expect(page).to have_content distance_of_time_in_words(@past_visit.end_time, Time.now, include_seconds: true)
end

Given(/^I am logged in and in between visits$/) do
  @doc_user = FactoryGirl.create(:user, id: 1)
  @patient = FactoryGirl.create(:user, id: 2, password: "testword")
  @doctor = FactoryGirl.create(:doctor, id: 1, user_id: 1)
  @past_visit = FactoryGirl.create(:visit, doctor_id: 1, patient_id: 2,
                             start_time: Time.now,
                             end_time: Time.now + 1.seconds)
  @upcoming_visit = FactoryGirl.create(:visit, doctor_id: 1, patient_id: 2,
                             start_time: Time.now + 15.minutes,
                             end_time: Time.now + 30.minutes)
  sleep(2)
  visit('/login')
  fill_in 'session[username]', with: @patient.username
  fill_in 'session[password]', with: "testword"
  find("#LoginSubmit").click
end

Given(/^I am logged in and have never booked a visit$/) do
  @user = FactoryGirl.create(:user, password: "testword")
  visit('/login')
  fill_in 'session[username]', with: @user.username
  fill_in 'session[password]', with: "testword"
  find("#LoginSubmit").click
end

Then(/^I see a message that says "(.*?)"$/) do |arg1|
  expect(page).to have_content arg1
end
Given(/^I want to sign up$/) do
  nil
end

When(/^I click the sign up button$/) do
  visit('/')
  find('#Signup').click
end

Then(/^I am redirected to the "(.*?)" page$/) do |arg1|
  page.should have_selector 'h1', text: arg1
end

Given(/^I filled in the signup form with all the right details$/) do
  User.delete_all
  visit('/signup')
#  @user = FactoryGirl.create(:user)
  #fill_in "user[username]", with: @user.username
  #fill_in "user[password]", with: @user.password
  #fill_in "user[password_confirmation]", with: @user.password
  #fill_in "user[firstname]", with: @user.firstname
  #fill_in "user[lastname]", with: @user.lastname
  #select @user.gender, :from => "user[gender]"
  #select @user.dob.strftime("%B"), :from => "user[dob(2i)]"
  #select @user.dob.day, :from => "user[dob(3i)]"
  #select @user.dob.year, :from => "user[dob(1i)]"
  fill_in "user[username]", with: "marguerite1996@live.com"
  fill_in "user[password]", with: "testword"
  fill_in "user[password_confirmation]", with: "testword"
  fill_in "user[firstname]", with: "Marguerite"
  fill_in "user[lastname]", with: "Alevarra"
  select "female", :from => "user[gender]"
  select "July", :from => "user[dob(2i)]"
  select "31", :from => "user[dob(3i)]"
  select "1996", :from => "user[dob(1i)]"
end

When(/^I click the "(.*?)" submit button$/) do |arg1|
  submit_name = "#" + arg1 + "Submit"
  find(submit_name).click
end

Then(/^I am taken to my user profile and see my first and last name$/) do
  expect(page).to have_content 'Marguerite Alevarra'
end

Then(/^I am logged in$/) do
  expect(page).to have_content 'Hey there, Marguerite!'
end

Given(/^I leave the "(.*?)" form blank$/) do |arg1|
  link = "/" + arg1
  visit(link)
end

Then(/^I see some errors$/) do
  expect(page).to have_content "can't be blank"
  expect(page).to have_content "errors"
end

Given(/^I want to sign up as a doctor$/) do
  nil
end

When(/^I click the For Doctors button$/) do
  visit('/')
  find("#Doctors").click
end

Given(/^I fill in the doctors form$/) do
  visit('/doctors/new')
  fill_in "temporary_credential[awarded_by]", with: "Medical Board of California"
  fill_in "temporary_credential[license_number]", with: "3425325252535"
  fill_in "temporary_credential[specialty_opt1]", with: "Emergency Medicine"
  fill_in "temporary_credential[specialty_opt2]", with: "Psychiatry"

  check("temporary_credential[general_practice]")

end

When(/^I click continue$/) do
  find("#DoctorContinue").click
end

Then(/^My credentials are listed on the profile$/) do
  #page.should have_selector 'h1', text: 'Doctor'
  expect(page).to have_content 'License Number'
end

Then(/^I am unverified$/) do
  expect(page).to have_content 'Unverified'
end
