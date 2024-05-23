require "application_system_test_case"
require 'webmock/minitest'

class AnnotatorPageTest < ApplicationSystemTestCase
    WebMock.allow_net_connect!
    def setup
        WebMock.disable!
        @apikey = LinkedData::Client.settings.apikey
        @host = LinkedData::Client.settings.rest_url
        @annotator_api = "https://services.stageportal.lirmm.fr/annotator"
        @ontologies_url = "#{@host}/ontologies?include_views=true"
        @annotator_text_area = ".annotator-page-text-area > textarea"
        @sample_response = fixtures(:annotator)["sample_response"]
        @sty_ontology = fixtures(:annotator)["sty_ontology"]
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
        find(@annotator_text_area).fill_in(with: 'Melanoma is a malignant tumor of melanocytes found mainly')
        WebMock.enable!
        stub_request(:get, "https://services.stageportal.lirmm.fr/annotator?class_hierarchy_max_level=None&confidence_threshold=0&score_threshold=0&text=Melanoma%20is%20a%20malignant%20tumor%20of%20melanocytes%20found%20mainly&whole_word_only=true")
            .with(
                headers: {
                        'Accept'=>'application/json',
                        'Authorization'=>'apikey token=1de0a270-29c5-4dda-b043-7c3580628cd5',
                        'Host'=>'services.stageportal.lirmm.fr:443',
                        'User-Agent'=>'NCBO API Ruby Client v0.1.0'
                })
            .to_return(status: 200, body: @sample_response.to_json, headers: {})
        
        
        find(".annotator-page-button #annotator").click

        assert_selector 'table#annotator-table'
        assert_equal 5, page.all('tr').count
        assert_selector '#annotator_json'
        assert_selector '#annotator_rdf'
        assert_selector '#annotator_cite_us'
        assert_selector '#annotator_api_doc'
        
        find(@annotator_text_area).native.clear
        find(@annotator_text_area).fill_in(with: 'mainly')

        stub_request(:get, "https://services.stageportal.lirmm.fr/annotator?class_hierarchy_max_level=None&confidence_threshold=0&score_threshold=0&text=mainly&whole_word_only=true")
            .with(
                headers: {
                        'Accept'=>'application/json',
                        'Authorization'=>'apikey token=1de0a270-29c5-4dda-b043-7c3580628cd5',
                        'Host'=>'services.stageportal.lirmm.fr:443',
                        'User-Agent'=>'NCBO API Ruby Client v0.1.0'
                })
            .to_return(status: 200, body: ([]).to_json, headers: {})

        find(".annotator-page-button #annotator").click

        assert_selector 'div.browse-empty-illustration'
        
        WebMock.disable!
    end

end