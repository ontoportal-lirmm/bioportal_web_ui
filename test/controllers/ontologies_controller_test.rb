# frozen_string_literal: true

require 'test_helper'

class OntologiesControllerTest < ActionDispatch::IntegrationTest
  ONTOLOGIES = LinkedData::Client::Models::Ontology.all(include: 'acronym')
  PAGES = %w[summary classes properties notes mappings schemes collections widgets].freeze

  test 'should return all the ontologies' do
    get ontologies_path
    assert_response :success
  end

  ONTOLOGIES.each do |ont|
    PAGES.each do |page|
      test "should get page #{page} of #{ont.acronym} ontology" do
        path = "#{ontologies_path}/#{ont.acronym}?p=#{page}"
        get path
        if response.redirect?
          follow_redirect!
        end
        assert_response :success, "GET #{path} returned #{response.status}"
      end
    end

    test "should open the tree views of #{ont.acronym} ontology" do
      paths = [
        ajax_classes_treeview_path(ontology: ont.acronym),
        ajax_properties_treeview_path(ontology: ont.acronym)
      ]
      paths.each do |path|
        begin
          get path
          assert_includes [404, 200], response.status,  "GET #{path} returned #{response.status}"
        rescue StandardError => e
          assert_equal ActiveRecord::RecordNotFound, e.class
        end
      end

    end
  end
end
