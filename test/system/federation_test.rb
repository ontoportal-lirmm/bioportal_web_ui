require "application_system_test_case"

class FederationTest < ApplicationSystemTestCase

  setup do
    @search_path = "/search"
    @query = "test"

    @ontologies_path = "/ontologies"

  end

  test "perform federated search in search page and make sure duplicates are managed correctly" do
    visit "#{@search_path}?q=#{@query}&lang=all&portals%5B%5D=agroportal&portals%5B%5D=ecoportal&portals%5B%5D=earthportal&portals%5B%5D=biodivportal"
    assert_selector ".search-page-number-of-results"

    results_titles = all("a.title div").map { |div| div.text.strip }

    assert_equal results_titles.count, results_titles.uniq.count, "There are duplicated results !"

  end


  test "perform federated search in browse page and make sure duplicates are managed correctly" do
    visit "#{@ontologies_path}?sort_by=ontology_name&portals=agroportal%2Cecoportal%2Cearthportal%2Cbiodivportal"
    loop do
      loading_element = find_all(".browse-sket").any?

      break unless loading_element

      page.execute_script("window.scrollBy(0, window.innerHeight)")

      sleep 0.3
    end

    ontologies_titles = all(".browse-ontology-title").map { |a| a.text.strip }

    assert_equal ontologies_titles.count, ontologies_titles.uniq.count, "There are duplicated results !"
  end



end
