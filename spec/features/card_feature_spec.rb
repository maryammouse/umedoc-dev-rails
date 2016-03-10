require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper

feature "cards", focus:true do
  scenario "when you click 'Update Details' you are taken to the proper page" do
    customer = FactoryGirl.create(:patient)
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now - 1.hours)..(Time.now + 1.minute + 1.hours)) # next_available
    otol = FactoryGirl.create(:oncall_times_online_location, oncall_time_id: oncall_time.id)

    visit('/')
    find_button("Book Now", match: :first).click

    find_link('Update Details').click

    expect(page).not_to have_content "Continue"
    expect(page).to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario "when you fill in the update form and hit submit, the current card is updated." do
    customer = FactoryGirl.create(:patient)
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/cards')

    fill_in 'update[zipcode]', with: '23901'

    find('#UpdateSubmit').click

    expect(page).to have_content "Zip Code: 23901"
    expect(page).to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario "when you fill in the create form and hit submit, a new card is added." do
    customer = FactoryGirl.create(:patient)
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/cards')

    fill_in 'create[number]', with: '5555555555554444'
    select '12', from: 'create[exp_month]'
    select '2018', from: 'create[exp_year]'
    fill_in 'create[zipcode]', with: '90034'
    fill_in 'create[cvc]', with: '500'

    find('#CreateSubmit').click
    
    expect(page).to have_select('card[selected]', with_options: ['Card ending in 4444', 'Card ending in 4242'])
    expect(page).to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario "when you click a new card from the 'Select a Card' dropdown, a new card is selected" do
    customer = FactoryGirl.create(:patient)
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/cards')

    fill_in 'card[number]', with: '5555555555554444'
    select '12', from: 'create[exp_month]'
    select '2018', from: 'create[exp_year]'
    fill_in 'create[zipcode]', with: '90034'
    fill_in 'create[cvc]', with: '500'

    find('#CreateSubmit').click

    select 'Card ending in 4242', from: 'card[selected]'
    
    expect(page).to have_content 'Currently selected: Visa Card ending in 4242'
    expect(page).to have_select('card[selected]', with_options: ['Card ending in 4444', 'Card ending in 4242'])
    expect(page).to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario "when you click 'DELETE CURRENT CARD' it is deleted from the 'select' dropdown and is not selected" do
    customer = FactoryGirl.create(:patient)
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/cards')

    fill_in 'card[number]', with: '5555555555554444'
    select '12', from: 'create[exp_month]'
    select '2018', from: 'create[exp_year]'
    fill_in 'create[zipcode]', with: '90034'
    fill_in 'create[cvc]', with: '500'

    find('#CreateSubmit').click

    select 'Card ending in 4242', from: 'card[selected]'

    find_button('DELETE CURRENT CARD').click

    
    expect(page).to have_content 'Currently selected: MasterCard Card ending in 4444'
    expect(page).to have_select('card[selected]', with_options: ['Card ending in 4444'])
    expect(page).not_to have_select('card[selected]', with_options: ['Card ending in 4242'])
    expect(page).to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario "You can access the page without any cards available (and not receive an error)" do
    customer = FactoryGirl.create(:patient)
    StripeCustomer.destroy_all
    customer.user.password = 'testword'
    customer.user.save!
    visit('/login')
    fill_in "session[username]", with: customer.user.username
    fill_in "session[password]", with: 'testword'
    find("#LoginSubmit").click

    visit('/cards')


    expect(page).to have_content 'Currently selected: none'
    expect(page).not_to have_select('card[selected]')
    expect(page).not_to have_content 'Update Your Card'
    expect(page).to have_content 'Add New Card'
  end

  scenario 'when you update, it renders the correct error message if the zipcode is not in the database' do
      customer = FactoryGirl.create(:patient)
      customer.user.password = 'testword'
      customer.user.save!
      visit('/login')
      fill_in "session[username]", with: customer.user.username
      fill_in "session[password]", with: 'testword'
      find("#LoginSubmit").click

      visit('/cards')

      fill_in "update[zipcode]", with: '4151316136161'
      select '12', from: 'update[exp_month]'
      select '2018', from: 'update[exp_year]'

      find("#UpdateSubmit").click


      expect(page).to have_content "That is not a valid zipcode in our database. Sorry!"
      expect(page).to have_content 'Update Your Card'
      expect(page).to have_content 'Add New Card'
    end
end
