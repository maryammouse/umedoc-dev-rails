require 'rails_helper'

RSpec.describe MailingList, type: :model do
    it "is invalid with incorrect email" do
      email = build(:mailing_list,
                   :email => 'maryam@kldskfjsalfjs')
      email.valid?
      expect(email.errors[:email]).to include("is not valid in our system. Sorry about that!")
    end

  it "is valid with a correct email" do
    email = build(:mailing_list, email: 'maryamsyed2096@gmail.com')

    email.valid?
    expect(email).to be_valid
  end
end
