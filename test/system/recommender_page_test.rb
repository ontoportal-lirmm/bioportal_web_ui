require "application_system_test_case"
require 'webmock/minitest'

class RecommenderPageTest < ApplicationSystemTestCase
    def setup
        WebMock.disable_net_connect!(allow_localhost: true)
        @recommender_submit_button = "div.recommender-page-button"
    end

    test "go to recommender page and check if all filters and inputs are there" do
        visit root_url
        click_link(href: '/recommender')
        
        assert_selector "textarea#recommender-text-area"
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
        find("div.insert-sample-text-button").find("div.button").click
        WebMock.enable!
        stub_request(:post, "/recommender")
            .with(
                body: {
                    input: "Melanoma is a malignant tumor of melanocytes found mainly in the skin but also in the intestine and the eye.",
                    input_type: 1,
                    output_type: 1,
                    wc: 0.55,
                    wa: 0.15,
                    wd: 0.15,
                    ws: 0.15,
                    max_elements_set: 3
                }
            )
            .to_return(
                status: 200,
                body: '{"recommendations": ["Recommendation 1", "Recommendation 2"]}',
                headers: { 'Content-Type' => 'application/json' }
            )
        
        find(@recommender_submit_button).click
        sleep 20
        WebMock.disable!
    end
end
