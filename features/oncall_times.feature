@wip
Feature: The page where a doctor can enter their availability to see patients

    Background:
    In order to be able to see patients with a fee and at a time and place that is convenient to me
    As a registered doctor on Umedoc
    I want to be able to enter my Oncall Time Availability


    #Given Context
    #When Action / Event
    #Then Outcome

    Scenario:
        Given   I am not a registered user on the site
        When    I try to visit the oncall_times_entry form page
        Then    I should be redirected to the sign in page

    Scenario:
        Given   I am a registered user
        But     I am not a registered doctor on the site
        When    I try to visit the oncall_times_entry form page
        Then    I should be redirected to the patient welcome page

    Scenario:
        Given   I am a registered user and doctor
        But     I am not a verified doctor on the site
        When    I try to visit the oncall_times_entry form page
        Then    I should see a page explaining that I must be verified before I can enter my oncall_times availability
        And     I should see a summary of steps needed to complete verification.



    Scenario:
        Given   I am a verified doctor on the site
        But     I don't have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    I should be directed to the fee_schedule entry page

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The title-bar should say "Umedoc"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The page should say "Oncall Times"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The page should say "An Oncall Time is a period of time during which you are available to see patients"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The page should say "Enter the dates and times when you are available to see patients"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The page should say "Start date and time of Oncall Time"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I visit the oncall_times_entry form page
        Then    The page should say "End date and time of Oncall Time"

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I enter an oncall_time with all required information
        Then    The new oncall_time will be listed on the page


    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I enter an oncall_time with all required information
        Then    The relevant fee_schedule rules will be listed on the page

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I enter an oncall_time with all required information
        Then    The resulting 'actual_availability' will be listed on the page with an explanation

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I enter an oncall_time with all required information
        Then    There will be a link to enter further fee rules to match the given oncall_times

    Scenario:
        Given   I am a verified doctor on the site
        And     I have a fee_schedule defined
        When    I enter an oncall_time with all required information
        Then    There is a button to enter a new fee rule to extend the partial fee rule to the given oncall_time
