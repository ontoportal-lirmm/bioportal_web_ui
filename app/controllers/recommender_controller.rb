class RecommenderController < ApplicationController
  layout :determine_layout
  include ApplicationHelper

  # REST_URI is defined in application_controller.rb
  RECOMMENDER_URI = "/recommender"

  def index
    @text = params[:text]
    @results_table_header = [t('recommender.results_table.ontology'), t('recommender.results_table.final_score'), 
                              t('recommender.results_table.coverage_score'), t('recommender.results_table.acceptance_score'),
                              t('recommender.results_table.detail_score'), t('recommender.results_table.specialization_score'),
                              t('recommender.results_table.annotations')
                            ]
    @advanced_options_open = false 
    if params[:max_elements_set]
      @not_valid_max_num_set = (params[:max_elements_set] < '2') || (params[:max_elements_set] > '4')
    end
    unless params[:input].nil?  ||  params[:input].empty? || @not_valid_max_num_set
      recommendations = LinkedData::Client::HTTP.post(RECOMMENDER_URI, params)
      @advanced_options_open = !recommender_params_empty?
      @results = []
      @json_link = "#{$REST_URL}/recommender?input=#{params[:input]}&apikey=#{$API_KEY}&ontologies=#{params[:ontologies]}&max_elements_set=#{params[:max_elements_set]}&input_type=#{params[:input_type]}&output_type=#{params[:output_type]}&wc=#{params[:wc]}&wa=#{params[:wa]}&wd=#{params[:wd]}&ws=#{params[:ws]}"
      recommendations.each do |recommendation|
        row = {
          ontologies: recommendation_ontologies(recommendation),
          final_score: percentage(recommendation.evaluationScore),
          coverage_score: percentage(recommendation.coverageResult.normalizedScore),
          acceptance_score: percentage(recommendation.acceptanceResult.normalizedScore),
          details_score: percentage(recommendation.detailResult.normalizedScore),
          specialization_score: percentage(recommendation.specializationResult.normalizedScore),
          annotations: recommendation_annotations(recommendation),
          highlighted: false,
        }
        @results.push(row)
        @results.max_by { |element| element[:final_score] }[:highlighted] = true
      end
    end
  end

  def recommendation_ontologies(recommendation)
    recommendation.ontologies.map { |ont| { acronym: ont.acronym, link: ont.id } }
  end

  def recommendation_annotations(recommendation)
    recommendation.coverageResult.annotations.map{|annotation| {text: annotation.text, link: url_to_endpoint(annotation.annotatedClass.links['self'])}}
  end

  def percentage(string)
    result = string.to_f * 100
    result.round(1).to_s
  end

  def recommender_params_empty?
    (params[:wc].eql?('0.55') && params[:wa].eql?('0.15') && params[:wd].eql?('0.15') && params[:ws].eql?('0.15') && params[:max_elements_set].eql?('3') && params[:ontologies].nil?)
  end
end
