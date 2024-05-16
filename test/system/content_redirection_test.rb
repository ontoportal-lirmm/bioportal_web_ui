require "application_system_test_case"
require 'webmock/minitest'

class ContentRedirectionTest < ApplicationSystemTestCase
    def setup
        WebMock.disable!
        
        @sty_url = root_url+'ontologies/STY'
        @ontology_portal_uri = 'div.field-container p.field-description_text'
        @htaccess_button = 'a[data-show-modal-title-value="Rewrite rules for STY ontology"]'
        @redirection_modal = 'div#redirection_rules_modal'
        @htaccess_code = 'div.htacess-code-container'
        @nginx_code = 'div.nginx-code-container'
        @contact_support_button = 'div.contact-support'

        @generate_portal_link_button = 'span#generate_portal_link'
        @accordion_concept_details = '.dropdown-title-bar[data-target="#accordion-concept-details"]'
        @resource_div_formats = 'div#content_resource_formats' #'div.d-flex.justify-content-center.p-2'
    end


    test "go to STY ontology page and test the htaccess button" do
        visit @sty_url
        assert_selector @ontology_portal_uri , text: $SITE + ' URI'
        assert_selector @htaccess_button
        sleep 1
        find(@htaccess_button).click
        assert_selector(@redirection_modal, visible: true, wait: 10)
        assert_selector @htaccess_code
        assert_selector @nginx_code
        assert_selector @contact_support_button
        find('button[data-action="turbo-modal#hide"]').click
        sleep 1
    end

    test "go to STY ontology classes page and test the different format of resource" do
        visit @sty_url
        click_link('Classes')
        assert_selector(@generate_portal_link_button, visible: true, wait: 10)
        # find(@generate_portal_link_button + " .clipboard.d-flex.align-items-center").find('div[data-clipboard-target="content"]', visible: :all).native.attribute('innerHTML').strip
        find(@generate_portal_link_button, visible: :all).click
        assert_selector(@accordion_concept_details, visible: true, wait: 10)
        find(@accordion_concept_details, visible: :all).click
        assert_selector(@resource_div_formats, visible: true)
        
        all_button_format = find_all('div#content_resource_formats a')
        all_button_format.each do |link|
            link.click
            sleep 2
            find('button.close[data-action="turbo-modal#hide"]').click
            sleep 1
        end
    end


end