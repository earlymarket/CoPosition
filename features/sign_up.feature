Feature: Sign up and log in

  Scenario: Developer login
    Given I am on the homepage
      And I click "Developers"
      Then I click the link "Sign up!"
    When I fill in the form with my "developer" details
      And I click "Sign up"
    Then I should see "You have signed up successfully."

  Scenario: User login
    Given I am on the homepage
      And I click "User log in"
      Then I click the link "Sign up!"
    When I fill in the form with my "user" details
      And I click "Sign up"
    Then I should see "You have signed up successfully."
