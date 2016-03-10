Feature: Logging into one's account

    A user should be able to, once they have an account
    Login
    See info when logged in they can't see when logged out
    Log out

    Scenario:
        Given   I want to login
        When    I click the login button
        Then    I am redirected to the "Login" page

    Scenario:
        Given   I want to login
        When    I fill in the login form and click the submit button
        Then    I am taken to my user profile and see my first and last name
        And     I am logged in

    Scenario:
        Given   I leave the "login" form blank
        When    I click the "Login" submit button
        Then    I see a login error

    Scenario:
        Given   I am logged in and want to logout
        When    I click the logout button
        Then    I am redirected to the "Umedoc" page
        And     I am logged out

    Scenario:
        Given   I am logged in and want to close my browser
        When    I close my browser, reopen it, and go to Umedoc
        Then    I am logged in
