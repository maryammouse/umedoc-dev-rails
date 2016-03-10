require 'rails_helper'
require 'spec_helper'

feature "user", focus:true do
  


  scenario "You can see doctor profiles while logged out" do
    doctor = FactoryGirl.create(:doctor)
    visit "/users/" + doctor.user.id.to_s
    expect(page).to have_content doctor.user.firstname
  end

  scenario "Doctors can visit other doctor's profiles without seeing stripe" do
    doctor = FactoryGirl.create(:doctor)
    doctor2 = FactoryGirl.create(:doctor)
    user = doctor2.user
    page.set_rack_session(user_id: user.id)
    visit "/users/" + doctor.user.id.to_s
    expect(page).not_to have_content "Get Paid"
  end

  scenario "Doctor profiles show blurbs if they exist" do
    doctor = FactoryGirl.create(:doctor)
    visit "/users/" + doctor.user.id.to_s
    expect(page).to have_content "Ahmazing"
  end
  
  
  scenario "Doctor profiles DO NOT show blurbs if they DO NOT exist" do
    doctor = FactoryGirl.create(:doctor, blurb: nil)
    visit "/users/" + doctor.user.id.to_s
    expect(page).not_to have_content "Ahmazing"
  end


  scenario "Doctor profiles show Linked_In if it exists" do
    doctor = FactoryGirl.create(:doctor)
    visit "/users/" + doctor.user.id.to_s
    expect(page).to have_content "View my profile"
  end


  scenario "Doctor profiles DO NOT show Linked_In if it DOES NOT exist" do
    doctor = FactoryGirl.create(:doctor, blurb: nil, linked_in: nil)
    visit "/users/" + doctor.user.id.to_s
    expect(page).not_to have_content "View my profile"
  end

  scenario "Friendly url works for doctor profiles" do
    doctor = FactoryGirl.create(:doctor)
    url = "/" + doctor.user.lastname.downcase
    visit url

    expect(page).to have_content "Doctor " + doctor.user.firstname + " " + doctor.user.lastname
  end

end
