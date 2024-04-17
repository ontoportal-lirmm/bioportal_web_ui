# frozen_string_literal: true

require 'open-uri'
require 'net/http'
require 'uri'
require 'cgi'

class AjaxProxyController < ApplicationController
  def get
    page = open(params[:url])
    content = page.read
    render text: content
  end

  def json_class
    not_found if params[:conceptid].nil? || params[:conceptid].empty?
    params[:ontology] ||= params[:ontologyid]

    if params[:ontologyid].to_i.positive?
      params_cleanup_new_api
      stop_words = %w[controller action ontologyid]
      redirect_to "#{request.path}#{params_string_for_redirect(params, stop_words: stop_words)}",
                  status: :moved_permanently
      return
    end

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    not_found if @ontology.nil?

    @concept = @ontology.explore.single_class({}, params[:conceptid])
    not_found if @concept.nil?

    render_json @concept.to_json
  end

  def json_ontology
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    not_found if @ontology.nil?
    simple_ontology = simplify_ontology_model(@ontology)  # application_controller (cached)
    render_json simple_ontology.to_json
  end

  def loading_spinner
    render partial: 'loading_spinner'
  end

  private

  def render_json(json, options = {})
    callback, variable = params[:callback], params[:variable]
    response = begin
      if callback && variable
        "var #{variable} = #{json};\n#{callback}(#{variable});"
      elsif variable
        "var #{variable} = #{json};"
      elsif callback
        "#{callback}(#{json});"
      else
        json
      end
    end
    render({ plain: response, content_type: 'application/json' }.merge(options))
  end
end
