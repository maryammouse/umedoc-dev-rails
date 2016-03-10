Feature: The first page that patients and doctors see on the site

    This should communicate the key messages:
        doctors are available NOW or at specific times
        the patients can book NOW
        the price of the visit is up-front
        the patients can learn about the doctors before booking
        patients can register ("Make this doctor your regular doctor")
        patients can see doctor just once
        patients can see the doctor online for many issues
        the site is NOT suitable for Emergency care
            the patient decides what is an emergency

            #Background:
            #    Given I might need a doctor

    #Given Context
    #When Action / Event
    #Then Outcome

    Scenario:
        Given   I want to visit the umedoc website
        When    I visit the website
        Then    The title-bar should say "Umedoc"

    Scenario:
        Given   I want to visit the umedoc website
        When    I visit the website
        Then    The page should say "Umedoc"

    Scenario:
        Given   I want to know what umedoc does
        When    I visit the website
        Then    The page should say "Find, visit and keep the perfect doctor for you"

    Scenario:
        Given   I want to know how umedoc works
        When    I visit the website
        Then    There should be a link for "How it Works"

    Scenario:
        Given   I want to book a doctor visit
        When    I visit the website
        Then    I should see the header "Available Doctors"

    Scenario:
        Given   I want to book a doctor visit
        When    I visit the website
        Then    I should see the "Time" the doctors are available

    #Scenario:
        #Given   I want to visit the umedoc website
        #When    I visit the website
        #But     There are no available appointments
        #Then    The page should say "No available appointments"
    # Maybe this kind of thing should be in a unit test??

    Scenario:
        Given   I want to book a doctor visit
        When    I visit the website
        Then    I should see the "Location" of the available appointments

    Scenario:
        Given   I want to book a doctor visit
        When    I visit the website
        Then    There should be a "book now" button next to each appointment time

    Scenario:
        Given   I want to book a doctor visit
        When    I visit the website
        Then    I should see if the visit will be "Online", "In-person" or "In-person and Online"

    Scenario:
        Given   I am concerned about cost
        When    I visit the website
        Then    I should see the "Cost" of each doctor visit

    Scenario:
        Given   I am concerned about cost
        When    I visit the website
        Then    I should see whether the doctor takes "Insurance"

    Scenario:
        Given   I am a registered user
        When    I select the "book now" button
        Then    I should be redirected to the booking page

    Scenario:
        Given   I am not a registered user
        When    I select the "book now" button
        Then    I should be redirected to the signup / signin page
        # later need to check that the session variable contains details of the appointment requested

    Scenario:
        Given   I want to visit the umedoc website
        When    I visit the website
        Then    There should be 2 fields on the right side of the page for the appointment search range input
        # I think each one should be a datetime picker, so two should be enough


    Scenario:
        Given   I want to visit the umedoc website
        When    I visit the website
        And     I enter a start and end datetime
        Then    The page should display a list of appointments in that time window

    Scenario:
        Given   I want to visit the umedoc website
        When    I visit the website
        And     I enter a start and end datetime
        But     There are no appointments available in that time window
        Then    The page should display "Sorry, there are no available appointments at those times"

    # Consider the scenarios below for version 2
    #Scenario:
        #Given   I want to visit the umedoc website
        #When    I visit the website
        #And    I enter a start and end datetime
        #But     There are no appointments available in that time window
        #Then    The page should display "The two nearest appointments to that time are"


    #Scenario:
        #Given   I want to visit the umedoc website
        #When    I visit the website
        #And    I enter a start and end datetime
        #But     There are no appointments available in that time window or before
        #Then    The page should display "Before your requested times"
        #And     The page should display "No Available Appointments"

    #Scenario:
        #Given   I want to visit the umedoc website
        #When    I visit the website
        #And     I enter a start and end datetime
        #But     There are no appointments available in that time window or after
        #Then    The page should display "After your requested times"
        #And     The page should display "No Available Appointments"


