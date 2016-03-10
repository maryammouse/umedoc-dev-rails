
Feature: Using the online office to conduct an appointment/visit
    The user and doctor should be able to visit the visit link,
    See the upcoming (already booked) appointment,
    View the video window,
    Have the video session start at the designated time,
    Talk to one another,
    End the session at the right time and let it be recorded as completed

    Scenario:
        Given   I want to see the online office and am logged out
        When    I visit the online office
        Then    I am redirected to the "Login" page
        And     I see a logged-out error

    Scenario:
        Given   I am logged in and have an upcoming visit
        When    I visit the Visit page
        Then    I see the upcoming visit
        And     The video window is not open

    Scenario:
        Given   I am logged in and it is time for my visit
        When    I visit the Visit page
        Then    The video window is open

    Scenario:
        Given   I am logged in and my most recent visit is ended
        When    I visit the Visit page
        Then    The video window is not open
        And     I see my most recent visit

    Scenario:
        Given   I am logged in and in between visits
        When    I visit the Visit page
        Then    I see the upcoming visit
        And     I see my most recent visit

    Scenario:
        Given   I am logged in and have never booked a visit
        When    I visit the Visit page
        Then    I see a message that says "You have no upcoming visits"
        And     I see a message that says "You haven't had a visit"
        And     I see a message that says "Book one here"
