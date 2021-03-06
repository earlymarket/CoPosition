require "rails_helper"

RSpec.feature "Devices", type: :feature do

  background do
    given_i_am_signed_in
    and_i_am_on_the_devices_page
  end

  scenario "User creates device and edits settings", js: true do
    when_i_create_a_new_device
    and_i_am_on_the_devices_page
    when_i_click_the_icon "public"
    then_i_should_see_enabled_icon "public"
    when_i_click_the_icon "cloud"
    then_i_should_see_disabled_icon "cloud"
    when_i_click_the_icon "visibility_off"
    then_i_should_see_enabled_icon "visibility_off"
    when_i_click_the_icon "timer"
    and_i_click_the_slider
    then_i_should_see_enabled_icon "timer"
  end

  def given_i_am_signed_in
    visit "/users/sign_up"
    fill_in "user_email", with: "tomm@email.com"
    fill_in "user_email_confirmation", with: "tomm@email.com"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    fill_in "user_username", with: Faker::Internet.user_name(4..20, %w(_ -))
    find(:css, "button.btn.waves-effect.waves-light").trigger("click")
  end

  def and_i_am_on_the_devices_page
    click_on "Devices", match: :first
    expect(page).to have_text("Your devices")
  end

  def when_i_create_a_new_device
    click_on "add"
    fill_in "device_name", with: "My_device"
    find("div.select-wrapper input").click
    find("div.select-wrapper li", text: "Laptop").click
    click_button "Add"
  end

  def when_i_click_the_icon(icon)
    click_link(icon, match: :first)
  end

  def then_i_should_see_enabled_icon(text)
    expect(page).to have_css("i.enabled-icon", :text => text)
  end

  def then_i_should_see_disabled_icon(text)
    expect(page).to have_css("i.disabled-icon", :text => text)
  end

  def and_i_click_the_slider
    find(:css, ".noUi-origin").trigger('click')
  end
end
