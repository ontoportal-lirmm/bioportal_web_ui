require "application_system_test_case"
require 'webmock/minitest'

class AnnotatorPageTest < ApplicationSystemTestCase
    def setup
        WebMock.disable!
        @apikey = LinkedData::Client.settings.apikey
        @host = LinkedData::Client.settings.rest_url
        @annotator_api = "https://services.stageportal.lirmm.fr/annotator"
        @annotator_text_area = "div#annotator_text_area"
    end

    test "go to annotator page and check if all the inputs and filters are there" do
        visit root_url
        click_link(href: '/annotator')
        assert_selector @annotator_text_area
    end

    test "go to annotator page insert sample text and get annotations"
        visit root_url
        click_link(href: '/annotator')
        find(@annotator_text_area).fill_in(with: 'Melanoma is a malignant tumor of melanocytes found mainly in the skin but also in the intestine and the eye.')
    end

end