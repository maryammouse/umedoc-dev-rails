require 'rails_helper'

feature 'Password Reset' do

  scenario "There is a forgot password link on the login page" do
    visit('/login')
    expect(page).to have_link 'Forgotten Password?'
  end

  scenario "When you click the link, you are taken to a page where you can enter your email" do
    visit('/login')
    find_link('Forgotten Password?').click
    expect(page).to have_content 'Reset Password'
    expect(page).to have_field 'email'
  end

  scenario "When you enter an email and hit submit, you are redirected to the homepage with a message" do
    user = create(:user)
    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: user.username
    find_button('Reset Password').click

    expect(page).to have_content 'If your account exists, an email was sent with password reset instructions.'
  end

  scenario "When you submit a valid email associated with an account, you receive a message in your inbox" do
    user = create(:user)
    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: user.username
    find_button('Reset Password').click

    expect(last_email.to).to include(user.username)

  end

  scenario "When you visit the url given in the email, you are taken to another password reset page" do
    user = create(:user)

    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: user.username
    find_button('Reset Password').click


    reset_url = '/password_resets/' + user.reload.password_reset_token + '/edit'

    visit(reset_url)

    expect(page).to have_content 'Reset Password'
    expect(page).to have_content 'Password confirmation'
    expect(page).to have_field 'Password'
  end

  scenario "When you change the password, a success message is displayed and you can log in with the new password." do
    patient = create(:patient)

    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: patient.user.username
    find_button('Reset Password').click

    reset_url = '/password_resets/' + patient.user.reload.password_reset_token + '/edit'

    visit(reset_url)

    fill_in 'Password', with: 'new_pass'
    fill_in 'Password confirmation', with: 'new_pass'

    find_button('Update Password').click

    expect(page).to have_content 'The password has been reset!'

    visit('/login')
    fill_in 'session[username]', with: patient.user.username
    fill_in 'session[password]', with: 'new_pass'

    find_button('Log in').click

    expect(page).to have_content 'Visits Notice Board'
    expect(page).to have_content 'Hey there, ' + patient.user.firstname + '!'
    expect(page).to have_content 'You have logged in! Nice one.'
  end

  scenario "When you type in mismatching password/password confirmation, you receive an error." do
    patient = create(:patient)

    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: patient.user.username
    find_button('Reset Password').click

    reset_url = '/password_resets/' + patient.user.reload.password_reset_token + '/edit'

    visit(reset_url)

    fill_in 'Password', with: 'new_pass'
    fill_in 'Password confirmation', with: 'failed_pass'

    find_button('Update Password').click

    expect(page).to have_content "Password confirmation doesn't match"

  end

  scenario "When you type in an invalid password, you receive an error." do
    patient = create(:patient)

    visit('/login')
    find_link('Forgotten Password?').click
    fill_in 'email', with: patient.user.username
    find_button('Reset Password').click

    reset_url = '/password_resets/' + patient.user.reload.password_reset_token + '/edit'

    visit(reset_url)

    fill_in 'Password', with: 'wantsodaN@O'
    fill_in 'Password confirmation', with: 'wantsodaN@O'

    find_button('Update Password').click

    expect(page).to have_content "Password has characters our system can't handle. We're sorry!"

  end


end