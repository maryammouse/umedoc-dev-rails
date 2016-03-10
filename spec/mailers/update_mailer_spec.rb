require "rails_helper"

RSpec.describe UpdateMailer, type: :mailer do
  it "Umedoc You mail has correct body/subject/from" do
    # Send the email, then test that it got queued
    list_item = MailingList.create(email: 'maryam@test.com', campaign: 'Umedoc You')
    email = UpdateMailer.confirm_update(list_item).deliver_now
    expect(ActionMailer::Base.deliveries.empty?).to be false

    # Test the body of the sent email contains what we expect it to
    expect(email.from).to eq(['maryam@umedoc.com'])
    expect(email.to).to eq(['maryam@test.com'])
    expect(email.subject).to eq('Coming Soon: Umedoc You')
    expect(email.html_part).to have_content('Umedoc You, a subscription')
  end

  it "House Call mail has correct body/subject/from" do
    # Send the email, then test that it got queued
    list_item = MailingList.create(email: 'maryam@test.com', campaign: 'House Calls')
    email = UpdateMailer.confirm_update(list_item).deliver_now
    expect(ActionMailer::Base.deliveries.empty?).to be false

    # Test the body of the sent email contains what we expect it to
    expect(email.from).to eq(['maryam@umedoc.com'])
    expect(email.to).to eq(['maryam@test.com'])
    expect(email.subject).to eq('Coming Soon: House Calls')
    expect(email.html_part).to have_content('our house call service')

  end
end
