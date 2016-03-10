
Feature: The signup - where people go to join the site

    The signup process should take a user to the signup page,
    allow them to fill in their details,
    make them an account if their details are appropriate
    and return errors if they aren't, so the user can try again

    Scenario:
        Given   I want to sign up
        When    I click the sign up button
        Then    I am redirected to the "Sign Up" page

    Scenario:
        Given   I filled in the signup form with all the right details
        When    I click the "Signup" submit button
        Then    I am taken to my user profile and see my first and last name
        And     I am logged in

    Scenario:
        Given   I leave the "signup" form blank
        When    I click the "Signup" submit button
        Then    I see some errors

    Scenario:
        Given   I want to sign up as a doctor
        When    I click the For Doctors button
        Then    I am redirected to the "Doctors" page

    Scenario:
        Given   I fill in the doctors form
        When    I click continue
        Then    I am redirected to the "Sign Up" page


    Scenario:
        Given   I fill in the doctors form
        When    I click continue
        Then    I am redirected to the "Sign Up" page
        And     I filled in the signup form with all the right details
        And     I click the "Signup" submit button
        Then    I am taken to my user profile and see my first and last name
        And     My credentials are listed on the profile
        And     I am unverified
