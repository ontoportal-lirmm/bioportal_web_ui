# frozen_string_literal: true

require 'test_helper'

class OntologiesControllerTest < ActionDispatch::IntegrationTest
  ONTOLOGIES = LinkedData::Client::Models::Ontology.all(include: 'acronym')
  PAGES = %w[summary classes properties notes mappings schemes collections widgets].freeze

  test 'should return all the ontologies' do
    get ontologies_path
    assert_response :success
  end

  ONTOLOGIES.sample(5).flat_map { |ont| PAGES.map { |page| [ont, page] } }.each do |ont, page|
    test "should get page #{page} of #{ont.acronym} ontology" do
      path = "#{ontologies_path}/#{ont.acronym}?p=#{page}"
      get path
      assert_response :success, "GET #{path} returned #{response.status}"
    end
  end
end
