require 'rails_helper'
require 'spec_helper'
require 'vcr'

feature "authy", focus:true do
  pro_key = 'GbSROAGJos1omNU0VOgzMbkUsDIsRopvOVGAj0Y2Ta4'
  pro_uri = 'http://api.authy.com'
  test_key = '7ea6e01f516b0a3ba8e9df75d1f9a6f6'
  test_uri = 'http://sandbox-api.authy.com'

  scenario "When you fill in the email field with an invalid email address,
            the correct error is displayed", driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_0' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testos@########"
      fill_in "temporary_user[cellphone]", with: "646-500-3791"
      sleep(2)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      expect(page).to have_content('Email is invalid')
    end
  end

  scenario "When you fill in the cellphone field with an invalid number,
            the correct error is displayed", driver: :poltergeist do
    Authy.api_key = test_key
    Authy.api_uri = test_uri
    visit('/signup')
    fill_in "temporary_user[username]", with: "testes@gmail.com"
    fill_in "temporary_user[cellphone]", with: "434-264-6214"
    sleep(1)
    find(:css, 'ul li', match: :first).click
    find("#PhoneContinue").click

    expect(page).to have_content('That is not a valid cellphone number.')
  end

  scenario "When you fill in the cellphone field with an valid number,
            the next signup page is displayed", driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_1' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "646-500-3791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      expect(page).to have_content('Verify')
    end
  end

  scenario "When you fill in the token field with an invalid code,
            the correct error is displayed", driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_2' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "646-500-3791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "T0tally valid toekn"
      find("#TokenContinue").click

      expect(page).to have_content("The code was invalid. Please re-enter it or request a new one.")
    end
  end

  scenario "When you fill in the token field with a valid code,
            the next signup page is displayed", driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_5' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "646-500-3791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "0000000"
      find("#TokenContinue").click

      expect(page).to have_content("Almost There")
    end
  end

  scenario 'When you fill in the third signup page with valid information,
            the correct page is displayed', driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_3' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "6465003791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "0000000"
      find("#TokenContinue").click

      visit('/signup_part3')
      fill_in "user[firstname]", with: "Sarah"
      fill_in "user[lastname]", with: "Anderson"
      fill_in "user[password]", with: "shoppingandstuff"
      fill_in "user[password_confirmation]", with: "shoppingandstuff"
      sleep(1)
      find("#SignupSubmit").click

      expect(page).to have_content('Sarah')
    end
  end

  scenario 'When you fill in the firstname field with invalid data,
            the correct error is displayed', driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_3' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "6465003791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "0000000"
      find("#TokenContinue").click

      visit('/signup_part3')
      sleep(1)
      fill_in "user[firstname]", with: "@@@@@@@@@@@"
      fill_in "user[lastname]", with: "Anderson"
      fill_in "user[password]", with: "shoppingandstuff"
      fill_in "user[password_confirmation]", with: "shoppingandstuff"
      find("#SignupSubmit").click

      expect(page).to have_content("The first name has characters our system can't handle. We're sorry!")
    end
  end

  scenario 'When you fill in the lastname field with invalid data,
            the correct error is displayed', driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_3' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "6465003791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "0000000"
      find("#TokenContinue").click

      visit('/signup_part3')
      fill_in "user[firstname]", with: "Sarah"
      fill_in "user[lastname]", with: "@@@@@@@@@@@@"
      fill_in "user[password]", with: "shoppingandstuff"
      fill_in "user[password_confirmation]", with: "shoppingandstuff"
      sleep(1)
      find("#SignupSubmit").click

      expect(page).to have_content("The last name has characters our system can't handle. We're sorry!")
    end
  end

  scenario 'When you fill in the password field with too many characters,
            the correct error is displayed', driver: :poltergeist do
    Authy.api_key = pro_key
    Authy.api_uri = pro_uri
    VCR.use_cassette 'authy_phoneintel_api_3' do
      visit('/signup')
      fill_in "temporary_user[username]", with: "testes@gmail.com"
      fill_in "temporary_user[cellphone]", with: "6465003791"
      sleep(1)
      find(:css, 'ul li', match: :first).click
      find("#PhoneContinue").click

      Authy.api_key = test_key
      Authy.api_uri = test_uri
      visit('/signup_part2')
      sleep(1)
      fill_in "verification[token]", with: "0000000"
      find("#TokenContinue").click

      visit('/signup_part3')
      fill_in "user[firstname]", with: "Sarah"
      fill_in "user[lastname]", with: "Anderson"
      fill_in "user[password]", with: "Princesslnnaasasfsdfasfasfsafsafsakfshfashfkasdfhkasfhaskfafsdfasfdsfasfasfasfsd"
      fill_in "user[password_confirmation]", with: "Princesslnnaasasfsdfasfasfsafsafsakfshfashfkasdfhkasfhaskfafsdfasfdsfasfasfasfsd"
      sleep(1)
      find("#SignupSubmit").click

      expect(page).to have_content("Password is too long (maximum is 72 characters)")
    end
  end


  Authy.api_key = test_key
  Authy.api_uri = test_uri

end
