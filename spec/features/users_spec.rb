require "rails_helper"

RSpec.feature "Users", type: :feature do
  let(:user) { FactoryGirl.create :user }

  scenario "User signs up" do
    given_i_fill_in_sign_up_details
    and_i_click_sign_up
    then_i_should_see_device_creation
  end

  scenario "User signs up with taken email" do
    given_i_fill_in_sign_up_details
    fill_in "user_email", with: user.email
    and_i_click_sign_up
    then_i_should_see_sign_up
  end

  scenario "User signs in, edits account and signs out" do
    given_i_fill_in_log_in_details
    and_i_click_log_in
    then_i_should_see_welcome_page
    when_i_visit_edit_page
    and_i_edit_my_username
    then_i_should_see_a_new_username
    when_i_log_out
    then_i_should_be_logged_out
  end

  def given_i_fill_in_sign_up_details
    visit "/users/sign_up"
    fill_in "user_email", with: "example@email.com"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    fill_in "user_username", with: "example"
  end

  def given_i_fill_in_log_in_details
    visit "/users/sign_in"
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
  end

  def and_i_click_log_in
    click_button "Log in"
  end

  def and_i_click_sign_up
    click_button "Sign up"
  end

  def then_i_should_see_device_creation
    expect(page).to have_text "Device Creation"
  end

  def then_i_should_see_welcome_page
    expect(page).to have_text "Hello #{user.username}"
  end

  def then_i_should_see_sign_up
    expect(page).to have_text "Sign up"
  end

  def when_i_visit_edit_page
    click_on "settings"
  end

  def and_i_edit_my_username
    fill_in "user_username", with: "changed"
    fill_in "user_current_password", with: user.password
    click_on "Update"
  end

  def then_i_should_see_a_new_username
    click_on "Dashboard", match: :first
    expect(page).to have_text "Hello changed"
  end

  def when_i_log_out
    click_on "Log Out"
  end

  def then_i_should_be_logged_out
    expect(page).to have_text "User Log In"
  end
end
