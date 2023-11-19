require "test_helper"
require_relative 'helpers/application_test_helpers'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ApplicationTestHelpers::Ontologies
  include ApplicationTestHelpers::Users
  include ApplicationTestHelpers::Users
  include ApplicationTestHelpers::Categories
  include ApplicationTestHelpers::Groups

  driven_by :selenium, using: :chrome, options: {
    browser: :remote,
    url: "http://localhost:4444"
  }

  def login_in_as(user)
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

    # Click on the Tom Select input to open the dropdown
    find("#{real_select} + div").click
    sleep 1

    return unless page.has_selector?("#{real_select} + div > .ts-dropdown")

    if multiple
      # reset the input to empty
      all("#{real_select} + div > .ts-control > .item .remove").each do |element|
        element.click
      end

      page.execute_script("document.querySelector(\"#{real_select} + div > .ts-control\").innerHTML = '';")
    else
      values = Array(values)
    end

    within "#{real_select} + div > .ts-dropdown > .ts-dropdown-content" do


      values.each do |value|
        if page.has_selector?('.option', text: value)
          find('.option', text: value).click
        end
      end
    end

    if multiple
      find("#{real_select} + div").click
      sleep 1
    end
  end


  def date_picker_fill_in(selector, value)
    page.execute_script("document.querySelector(\"[name='#{selector}']\").flatpickr().setDate('#{value}')")
  end

end
