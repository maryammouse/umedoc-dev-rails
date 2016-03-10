require 'rails_helper'

feature "how it works", focus:true do
  
  scenario "Someone visits the how it works page, it has the required content" do
    visit('/howitworks')

    expect(page).to have_content "How it Works"
    expect(page).to have_content "Seeing a Doctor"
    expect(page).to have_content "Book Your Visit"
    expect(page).to have_content "Seeing Patients"
    expect(page).to have_content "Sign Up as a Doctor"
    expect(page).to have_content "Connect With Stripe"
    expect(page).to have_content "Record your Availability"
    expect(page).to have_content "Visit Time"
  end

  # need to add code to check for correct images, maybe by name?
  # and make sure the actual image downloaded?
end
