require 'rails_helper'
require 'spec_helper'
include ActionView::Helpers::DateHelper
include PromotionsHelper

feature "interest mailing", focus:true do

  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'


  scenario "when I put in my email it is added to the mailing list and a confirmation is sent" do
    visit('/subscribe')
    expect(page).to have_content 'Umedoc You'

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    expect(MailingList.all).not_to be_empty
    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end

  scenario "When I input an invalid email the error message is displayed" do
    visit('/subscribe')
    expect(page).to have_content 'Umedoc You'

    fill_in "email", with: "; (delete from users); "
    find('#MailingListContinue').click

    expect(MailingList.all).to be_empty
    expect(page).to have_content 'is not valid in our system. Sorry about that! Please try again.'
  end

  scenario "The house calls landing page an also add an email to the MailingList" do
    visit('/house_calls')
    expect(page).to have_content 'House calls'

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    expect(MailingList.all).not_to be_empty
    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end

  scenario "If I have already subscribed to updates from a certain campaign,
I can't use that email again (For that campaign)" do
    visit('/house_calls')
    expect(page).to have_content 'House calls'

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    expect(page).to have_content 'Email has already been used'

  end

  scenario " I can subscribe to updates from house calls and Umedoc You with the same email" do
    visit('/subscribe')
    expect(page).to have_content 'Umedoc You'

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    visit('/house_calls')
    expect(page).to have_content 'House calls'

    fill_in "email", with: "maryamsyed2096@gmail.com"
    find('#MailingListContinue').click

    expect(MailingList.all.count).to eq(2)
    expect(ActionMailer::Base.deliveries.last).not_to equal(nil)
  end

  scenario "When I unsubscribe my email is removed from the list" do
    email = 'maryamsyed2096@gmail.com'
    MailingList.create(email: email, campaign: 'Umedoc You')
    visit('/unsubscribe_mail?email=' + email)
    find('#UnsubscribeSubmit').click

    expect(page).to have_content 'You have successfully unsubscribed. Please let us know if you have any further problems!'
    expect(MailingList.all).to be_empty
  end

  scenario "If a bad email is entered, mailing list is unchanged and app acts as normal." do
    MailingList.create(email: 'marguerite@ha.com', campaign:'Umedoc You')
    ml = MailingList.all
    email = 'badbadbad;haxor'
    visit('/unsubscribe_mail?email=' + email)
    find('#UnsubscribeSubmit').click

    expect(MailingList.all).not_to be_empty
    expect(page).to have_content 'The simple doctor service'


  end


end