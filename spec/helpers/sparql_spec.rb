require 'spec_helper'
require_relative '../../app/helpers/sparql_helper'
require 'active_support'
require 'pry'

describe 'change_from_clause' do
  include SparqlHelper

  before do
    $REST_URL = 'http://example.org'
  end

  let(:graph) { 'http://test.graph/ontology' }
  let(:trusted_graph) { 'http://secure.bioportal.org/trusted/graph' }

  let(:expected_query) do
    <<~EXPECTED.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      FROM <http://secure.bioportal.org/trusted/graph> WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    EXPECTED
  end

  let(:expected_query_with_graph) do
    <<~EXPECTED.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?x ?y ?Z FROM <http://secure.bioportal.org/trusted/graph> WHERE {
        GRAPH <http://secure.bioportal.org/trusted/graph> {
          ?x ?y ?Z
        }
      }
    EXPECTED
  end

  it 'work in normal case' do
    query = <<~SPARQL.strip
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT * WHERE {
        ?sub ?pred ?obj .
      } LIMIT 10
    SPARQL

    expected_result = <<~EXPECTED.strip
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT * FROM <#{trusted_graph}> WHERE {
        ?sub ?pred ?obj .
      } LIMIT 10
    EXPECTED

    check_query(query, expected_result)
  end

  it 'work with no FROM and no GRAPH and no WHERE' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email# {} WHAT ABOUT A COMMENT HERE
      WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    SPARQL

    check_query(query.dup, expected_query)
  end

  it 'handle normal FROM clause' do
    query = <<~SPARQL
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      FROM <http://data.bioontology.org/metadata/User> WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    SPARQL

    check_query(query, expected_query)
  end

  it 'handle normal FROM clause with no space' do
    query = <<~SPARQL
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email 
      FROM<http://data.bioontology.org/metadata/User> WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    SPARQL

    check_query(query, expected_query)
  end

  it 'handle prefix FROM clause' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      FROM meta:User WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    SPARQL

    check_query(query, expected_query)
  end

  it 'handles normal GRAPH' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?x ?y ?Z {  # This is a comment
        GRAPH <http://data.bioontology.org/metadata/User>{
          ?x ?y ?Z
        }
      }
    SPARQL

    check_query(query, expected_query_with_graph)
  end

  it 'handles normal GRAPH with no space' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?x ?y ?Z {  # This is a comment
        GRAPH<http://data.bioontology.org/metadata/User>{
          ?x ?y ?Z
        }
      }
    SPARQL

    check_query(query, expected_query_with_graph)
  end

  it 'handles prefixed GRAPH' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/> 
      SELECT DISTINCT ?x ?y ?Z {  # This is a comment
        GRAPH meta:User{ 
          ?x ?y ?Z 
        }
      }
    SPARQL

    check_query(query, expected_query_with_graph)
  end

  it 'handles combination of FROMs and GRAPHs' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?x ?y ?Z FROM meta:User FROM <http://data.bioontology.org/metadata/User>{# This is a comment

        GRAPH meta:User{
          ?x ?y ?Z
        }

        GRAPH meta:User2 {
          ?x ?y ?Z
        }
      }
    SPARQL

    expected_result = <<~EXPECTED.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?x ?y ?Z FROM <http://secure.bioportal.org/trusted/graph> FROM <http://secure.bioportal.org/trusted/graph>{
        GRAPH <http://secure.bioportal.org/trusted/graph> {
          ?x ?y ?Z
        }
        GRAPH <http://secure.bioportal.org/trusted/graph> {
          ?x ?y ?Z
        }
      }
    EXPECTED

    check_query(query, expected_result)
  end

  it 'handles removing comments from query' do
    query = <<~SPARQL
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> # {} FROM U HAVE BEEN PWNED 
      PREFIX meta: <http://data.bioontology.org/metadata/> # {} FROM U HAVE BEEN PWNED
      ### FROM U HAVE BEEN PWNED
      SELECT DISTINCT ?id ?apikey ?email# {} WHAT ABOUT A COMMENT HERE
      { # {} PWND
         ?id a <http://data.bioontology.org/metadata/User> . # {} PWND
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
         ?id <http://www.w3.org/1999/02/22-rdf-syntax-ns#label> ?label . # {} PWND
      }
      # {} PWND AGAIN SORRY
    SPARQL
    result = change_from_clause(query, trusted_graph)
    expected_result = <<~EXPECTED.strip
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
      PREFIX meta: <http://data.bioontology.org/metadata/> 
      SELECT DISTINCT ?id ?apikey ?email FROM <http://secure.bioportal.org/trusted/graph> WHERE { 
         ?id a <http://data.bioontology.org/metadata/User> . 
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
         ?id <http://www.w3.org/1999/02/22-rdf-syntax-ns#label> ?label . 
      }
    EXPECTED
    puts result
    expect(result.strip).to eq(expected_result)
  end

  it 'handle sub queries' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey
      WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
        {
         select ?id {  ?id ?s ?p }
        }

        {
         select ?id { graph meta:User {?id ?s ?p} }
        }
      }
    SPARQL

    expected_result = <<~EXPECTED.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey
      FROM <http://secure.bioportal.org/trusted/graph> WHERE {
        ?id a <http://data.bioontology.org/metadata/User> .
        ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
        {
         select ?id {  ?id ?s ?p }
        }
        {
         select ?id { GRAPH <http://secure.bioportal.org/trusted/graph> {?id ?s ?p} }
        }
      }
    EXPECTED
    check_query(query.dup, expected_result)
  end
  it 'handle number in select' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      1337# {} WHAT ABOUT A COMMENT HERE
      WHERE
      {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
       }
    SPARQL

    expect { check_query(query, expected_query) }.to raise_error(StandardError)
  end

  it 'handle fake from or graph' do
    query = <<~SPARQL.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      FROM <http://data.bioontology.org/metadata/where/select/graph> FROM <http://data.bioontology.org/metadata/User> WHERE 
      {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
       }
    SPARQL

    expected_result = <<~EXPECTED.strip
      PREFIX meta: <http://data.bioontology.org/metadata/>
      SELECT DISTINCT ?id ?apikey ?email
      FROM <http://secure.bioportal.org/trusted/graph> FROM <http://secure.bioportal.org/trusted/graph> WHERE
      {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
       }
    EXPECTED

    check_query(query, expected_result)
  end

  it 'handle invalid queries' do
    query = <<~SPARQL.strip
      SELECT DISTINCT ?id ?apikey ?email
      1337<#\{
      1337
      {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
         ?id <http://data.bioontology.org/metadata/email> ?email .
         ?id <http://data.bioontology.org/metadata/role> <http://data.bioontology.org/roles/ADMINISTRATOR> .
      }
    SPARQL

    expect { change_from_clause(query, trusted_graph) }.to raise_error(StandardError)
  end

  it 'handle fake select binding' do
    query = <<~SPARQL.strip
      SELECT  ?id ?email ?apikey ("{" AS ?PWNED) ('{"()(' AS ?PWNED2) ('  FROM  ' AS ?FROM) (  ' ) FROM  ' AS ?FROM2 ) ('GRAPH' AS ?GRAPH) ('WHERE' AS ?WHERE_) ('  {  ' AS ?bracket) 
      ("  { " AS ?bracket2)
      {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    SPARQL

    expected_result = <<~EXPECTED.strip
      SELECT  ?id ?email ?apikey ("{" AS ?PWNED) ('{"()(' AS ?PWNED2) ('  FROM  ' AS ?FROM) (  ' ) FROM  ' AS ?FROM2 ) ('GRAPH' AS ?GRAPH) ('' AS ?_) ('  {  ' AS ?bracket) 
      ("  { " AS ?bracket2) FROM <http://secure.bioportal.org/trusted/graph> WHERE {
         ?id a <http://data.bioontology.org/metadata/User> .
         ?id <http://data.bioontology.org/metadata/apikey> ?apikey .
      }
    EXPECTED

    check_query(query, expected_result)
  end



  private

  def check_query(query, expected)
    new_graph = 'http://secure.bioportal.org/trusted/graph'
    result = change_from_clause(query, new_graph)
    puts result
    expect(result.lines.map(&:rstrip).join("\n"))
      .to eq(expected.lines.map(&:rstrip).join("\n"))
  end
end

