require "application_system_test_case"
require 'webmock/minitest'

class RecommenderPageTest < ApplicationSystemTestCase
    def setup
        WebMock.disable!
        @apikey = LinkedData::Client.settings.apikey
        @host = LinkedData::Client.settings.rest_url
        @recommender_api = "#{@host}/recommender"
        @ontologies_url = "#{@host}/ontologies?include=acronym,name"

        ## Remove http:// from the host url
        uri = URI.parse(@host)
        @host = "#{uri.host}:#{uri.port}"

        @recommender_submit_button = "div.recommender-page-button"
        @recommender_text_area = "textarea#recommender-text-area"
        @sample_response = fixtures(:recommender)["sample_response"]
    end


    test "go to recommender page and check if all filters and inputs are there" do
        visit root_url
        click_link(href: '/recommender')
        assert_selector @recommender_text_area
        assert_selector "div.text-choice"
        assert_selector "div.keywords-choice"
        assert_selector "div.ontologies-choice"
        assert_selector "div.ontology-sets-choice"

        find("div.advanced-options-button").click

        assert_selector "div.weights-configuration"
        assert_selector ".ontologies.input"

        find("div.ontology-sets-choice").click

        assert_selector ".maxsets.input"
        assert_selector "div.insert-sample-text-button"
        assert_selector @recommender_submit_button
    end

    test "go to recommender page insert sample text and get recommendations" do
        visit root_url
        click_link(href: '/recommender')
        find(@recommender_text_area).fill_in(with: 'Melanoma is a malignant tumor of melanocytes found mainly in the skin but also in the intestine and the eye.')
        # Mock the response of the API calling /recommender with sample text
        WebMock.enable!
        WebMock.stub_request(:post, @recommender_api)
            .with(
                body: "{\"input\":\"Melanoma is a malignant tumor of melanocytes found mainly in the skin but also in the intestine and the eye.\",\"input_type\":\"1\",\"output_type\":\"1\",\"wc\":\"0.55\",\"wa\":\"0.15\",\"wd\":\"0.15\",\"ws\":\"0.15\",\"max_elements_set\":\"3\",\"controller\":\"recommender\",\"action\":\"index\"}",
                headers: {
                        'Accept'=>'application/json',
                        'Authorization'=>"apikey token=#{@apikey}",
                        'Content-Type'=>'application/json',
                        'Host'=>@host,
                        'User-Agent'=>'NCBO API Ruby Client v0.1.0'
                })
            .to_return(status: 200, body: @sample_response.to_json, headers: {})

        # Mock the response of the API calling /ontologies
        WebMock.stub_request(:get, @ontologies_url)
            .with(
              headers: {
                    'Accept'=>'application/json',
                    'Authorization'=>"apikey token=#{@apikey}",
                    'Host'=>@host,
                    'User-Agent'=>'NCBO API Ruby Client v0.1.0'
              })
            .to_return(status: 200, body: ([]).to_json, headers: {})

        
        find(@recommender_submit_button).click
        
        # Recommendations table exists
        assert_selector "div#recommender-table_wrapper"

        # The number of results is 4
        assert_equal 4, page.all('.recommender-result-ontology').count

        # The number of highlighted annotations are 5
        assert_selector ".recommender-page-text-area-results a", count: 5

        # Json button exists
        assert_selector "div.json-button"

        # Cite us button exists
        assert_selector "div.cite-us-button"

        # Go to annotator button exists
        assert_selector "div.go-to-annotator"
        
        find("div#recommender-edit-button").click
        
        
        find(@recommender_text_area).native.clear
        find(@recommender_text_area).fill_in(with: 'input to show no result')

        # Mock the response of the API calling /recommender using for an input that returns no results
        WebMock.stub_request(:post, "http://localhost:9393/recommender")
        .with(
          body: "{\"input\":\"input to show no result\",\"input_type\":\"1\",\"output_type\":\"1\",\"wc\":\"0.55\",\"wa\":\"0.15\",\"wd\":\"0.15\",\"ws\":\"0.15\",\"max_elements_set\":\"3\",\"controller\":\"recommender\",\"action\":\"index\"}",
          headers: {
                'Accept'=>'application/json',
                'Authorization'=>"apikey token=#{@apikey}",
                'Content-Type'=>'application/json',
                'Host'=>@host,
                'User-Agent'=>'NCBO API Ruby Client v0.1.0'
          })
          .to_return(status: 200, body: ([]).to_json, headers: {})

        find(@recommender_submit_button).click
        
        assert_selector "div.browse-empty-illustration"
        
        
    end
end
