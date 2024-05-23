require "application_system_test_case"
require 'webmock/minitest'

class AnnotatorPageTest < ApplicationSystemTestCase
    def setup
        WebMock.disable!
        @apikey = LinkedData::Client.settings.apikey
        @host = LinkedData::Client.settings.rest_url
        @annotator_api = "https://services.stageportal.lirmm.fr/annotator"
        @annotator_text_area = ".annotator-page-text-area > textarea"
    end

    test "go to annotator page and check if all the inputs and filters are there" do
        visit root_url
        click_link(href: '/annotator')
        assert_selector @annotator_text_area
        assert_selector 'div.insert-sample-text-button'
        assert_selector 'label[for="chips-whole_word_only-check"]'
        assert_selector 'label[for="chips-longest_only-check"]'
        assert_selector 'label[for="chips-expand_mappings-check"]'
        assert_selector 'label[for="chips-exclude_numbers-check"]'
        assert_selector 'label[for="chips-exclude_synonyms-check"]'
        assert_selector 'div.select-ontologies'
        find('div.advanced-options-button').click
        assert_selector '#umls_semantic_types_selector'
        assert_selector '#umls_semantic_groups_selector'
        assert_selector '#include_accentors'
        assert_selector '#include_score'
        assert_selector 'input[name="score_threshold"]'
        assert_selector 'input[name="confidence_threshold"]'
        assert_selector 'label[for="chips-fast_context-check"]'
        assert_selector 'label[for="chips-lemmatize-check"]'
    end

    test "go to annotator page insert sample text and get annotations" do
        visit root_url
        click_link(href: '/annotator')
        find(@annotator_text_area).fill_in(with: 'Melanoma is a malignant tumor of melanocytes found mainly in the skin but also in the intestine and the eye.')
    end

end