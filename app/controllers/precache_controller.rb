require "uri"

class PrecacheController < ApplicationController
  $UI_PORT = "80"
  # $UI_PORT = "3000"

  def self.precache_all(delete_cache = false)
    if delete_cache
      p "Deleting general cache info"
      CACHE.delete("act_ont_list")
      CACHE.delete("ont_list")
      CACHE.delete("ontology_acronyms")
      CACHE.delete("classes_all_ontologies")
    end

    get_url("http://localhost:#{$UI_PORT}")
    get_url("http://localhost:#{$UI_PORT}/ontologies")
    get_url("http://localhost:#{$UI_PORT}/mappings")
    precache_ontology_summary(delete_cache)
    precache_ontology_notes(delete_cache)
    precache_ontology_mappings(delete_cache)
    precache_ontology_classes(delete_cache)
  end

  def self.precache_ontology_classes(delete_cache = false)
    ontologies = DataAccess.getOntologyList
    ontologies.each do |ont|
      if delete_cache
        # remove relevant cache data
      end

      get_url("http://localhost:#{$UI_PORT}/ontologies/#{ont.ontologyId}?p=classes")
    end
  end

  def self.precache_ontology_summary(delete_cache = false)
    ontologies = DataAccess.getOntologyList
    ontologies.each do |ont|
      if delete_cache
        p "Deleting cache for #{ont.displayLabel}"
        CACHE.delete("#{ont.ontologyId}::_latest")
        CACHE.delete("#{ont.ontologyId}::_versions")
        CACHE.delete("#{ont.ontologyId}::_details")
        CACHE.delete("#{ont.ontologyId}::_metrics")
      end

      get_url("http://localhost:#{$UI_PORT}/ontologies/#{ont.ontologyId}")
    end
  end

  def self.precache_ontology_mappings(delete_cache = false)
    ontologies = DataAccess.getOntologyList
    ontologies.each do |ont|
      if delete_cache
        CACHE.delete("between_ontologies::map_count::#{ont.ontologyId}")
      end

      get_url("http://localhost:#{$UI_PORT}/ontologies/#{ont.ontologyId}?p=mappings")
    end
  end

  def self.precache_ontology_notes(delete_cache = false)
    ontologies = DataAccess.getOntologyList
    ontologies.each do |ont|
      if delete_cache
        # remove relevant cache data
      end

      get_url("http://localhost:#{$UI_PORT}/ontologies/#{ont.ontologyId}?p=notes")
    end
  end

  def self.get_url(url)
    p url
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 360

    begin
      timer = Time.now
      res = http.start { |con|
        path = uri.path.empty? ? "/" : uri.path
        con.get(path)
      }
      p "Retrieved in #{(Time.now - timer).to_f.round(2)}s"
    rescue Exception => e
      p "Failed to get #{url}: #{e.message}"
    end

    res.body
  end
end
