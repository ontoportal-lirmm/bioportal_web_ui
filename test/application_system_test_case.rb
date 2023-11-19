require "test_helper"
require_relative 'helpers/application_test_helpers'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ApplicationTestHelpers::Ontologies
  include ApplicationTestHelpers::Users
  include ApplicationTestHelpers::Users
  include ApplicationTestHelpers::Categories
  include ApplicationTestHelpers::Groups


  driven_by :selenium, using:  ENV['CI'].present? ? :headless_chrome : :chrome , screen_size: [1400, 1400] , options: {
      browser: :remote,
      url: "http://localhost:4444"
  }


  def login_in_as(user)
    create_user(user)

    visit login_index_url

    # Fill in the login form
    fill_in 'user_username', with: user.username
    fill_in 'user_password', with: user.password

    # Click the login button
    click_button 'Login'
  end

  def tom_select(selector, values)

    multiple = values.is_a?(Array)

    real_select = "[name='#{selector}']"

    ts_wrapper_selector = "#{real_select} + div.ts-wrapper"
    assert_selector ts_wrapper_selector

    # Click on the Tom Select input to open the dropdown
    find(ts_wrapper_selector).click
    sleep 1

    return unless page.has_selector?("#{ts_wrapper_selector} > .ts-dropdown")

    if multiple
      # reset the input to empty
      all("#{ts_wrapper_selector} > .ts-control > .item .remove").each do |element|
        element.click
      end
    else
      values = Array(values)
    end

    within "#{ts_wrapper_selector} > .ts-dropdown > .ts-dropdown-content" do
      values.each do |value|
        if page.has_selector?('.option', text: value)
          find('.option', text: value).click
        end
      end
    end

    if multiple
      find(ts_wrapper_selector).click
      sleep 1
    end
  end


  def date_picker_fill_in(selector, value)
    page.execute_script("document.querySelector(\"[name='#{selector}']\").flatpickr().setDate('#{value}')")
  end

end
