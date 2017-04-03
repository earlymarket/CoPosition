require "rails_helper"

RSpec.feature "Devices", type: :feature do

  background do
    given_i_am_signed_in
    and_i_am_on_the_devices_page
  end

  scenario "User creates then deletes device" do
    when_i_create_a_new_device
    then_i_should_see_the_device_map
    when_i_click_delete
    then_i_should_see_no_devices
  end

  scenario "User creates device and edits settings", js: true do
    when_i_create_a_new_device
    and_i_am_on_the_devices_page
    when_i_click_the_icon "cloud"
    then_i_should_see "Location fogging is off"
    when_i_click_the_icon "public"
    then_i_should_see "Location sharing is on"
    when_i_click_the_icon "visibility_off"
    then_i_should_see "Device cloaking is on"
    when_i_click_the_icon "timer"
    and_i_click_the_slider
    then_i_should_see "delayed by"
  end

  def given_i_am_signed_in
    visit "/users/sign_up"
    fill_in "user_email", with: Faker::Internet.email
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    fill_in "user_username", with: Faker::Internet.user_name(4..20, %w(_ -))
    click_on "Sign up"
  end

  def and_i_am_on_the_devices_page
    click_on "Devices", match: :first
    expect(page).to have_text("Your devices")
  end

  def when_i_create_a_new_device
    click_on "add"
    fill_in "device_name", with: "My device"
    click_button "Add"
  end

  def then_i_should_see_the_device_map
    expect(page).to have_text("Checkin now")
  end

  def when_i_click_the_icon(icon)
    click_link(icon, match: :first)
  end

  def then_i_should_see(text)
    expect(page).to have_text(text)
  end

  def and_i_click_the_slider
    find(:class, ".noUi-origin").click
  end

  def when_i_click_delete
    click_link "Delete device"
  end

  def then_i_should_see_no_devices
    expect(page).to have_text("Your devices")
    expect(page).not_to have_text("Device info")
  end
end
