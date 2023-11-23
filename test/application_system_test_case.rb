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


  def wait_for(selector, tries = 5)
    tries.times.each do
      break  if page.has_selector?(selector)
      sleep 1
    end
  end

  def wait_for_text(text, tries = 60)
    tries.times.each do
      sleep 1
      break  if page.has_text?(text)
    end
    assert_text text
  end

  def login_in_as(user)
    create_user(user)

    visit login_index_url

    # Fill in the login form
    fill_in 'user_username', with: user.username
    fill_in 'user_password', with: user.password

    # Click the login button
    click_button 'Login'
  end


  def assert_date(date)
    assert_text I18n.l(DateTime.parse(date), format: '%B %-d, %Y')
  end

  def search_input(selector, value)
    within "#{selector}" do
      find(".search-inputs .input-field-component").last.set(value)
      page.execute_script("document.querySelector('#{selector} > .search-inputs .input-field-component').dispatchEvent(new Event('input'))")
      sleep 1
      find(".search-inputs .search-content", text: value).click
      sleep 1
      find("input", text: 'Save').click
    end
  end
  def list_checks(selected_values, all_values = [])
    all_values.each do |val|
      uncheck val, allow_label_click: true
    end

    selected_values.each do |val|
      check val, allow_label_click: true
    end
  end

  def list_inputs(parent_selector, selector, values)
    within parent_selector do
      all('.delete').each { |x| x.click  }
      find('.add-another-object', text: 'Add another').click
      if values.is_a?(Hash)
        values.each do |key , val|
          all("[name^='#{selector}'][name$='[#{key}]']").last.set(val)
        end
      elsif values.is_a?(Array)
        values.each do |val|
          all("[name^='#{selector}']").last.set(val)
          find('.add-another-object', text: 'Add another').click
        end
      end

    end
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
