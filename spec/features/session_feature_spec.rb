require 'rails_helper'
include ActionView::Helpers::DateHelper

feature "session", focus:true do
  
  scenario "User is logged in when they input valid details" do
    patient = create(:patient)
    patient.user.password = "testword"
    patient.user.save

    visit('/login')

    fill_in 'session[username]', with: patient.user.username
    fill_in 'session[password]', with: "testword" #user.password

    find("#LoginSubmit").click

    expect(page).to have_content patient.user.firstname
  end
end
