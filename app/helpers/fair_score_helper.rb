module FairScoreHelper

  def user_apikey
    session[:user].nil? ? '' : session[:user].apikey
  end

  def fairness_service_enabled?
    !$FAIRNESS_DISABLED
  end

  def get_fairness_service_url(apikey = user_apikey)
    "#{$FAIRNESS_URL}?portal=#{$HOSTNAME.split('.')[0]}#{apikey.nil? || apikey.empty? ? '' : "&apikey=#{apikey}"}"
  end
  def get_fairness_json(ontologies_acronyms, apikey = user_apikey)
    begin
      MultiJson.load(Faraday.get(get_fairness_service_url(apikey) + "&ontologies=#{ontologies_acronyms}&combined").body.force_encoding('ISO-8859-1').encode('UTF-8'))
    rescue
      Rails.logger.warn "FAIRness service issue unreachable"
      {}
    end
  end

  def get_fair_score(ontologies_acronyms, apikey = user_apikey)
    get_fairness_json(ontologies_acronyms, apikey)['ontologies']
  end

  def get_fair_combined_score(ontologies_acronyms, apikey = user_apikey)
    get_fairness_json(ontologies_acronyms, apikey)['combinedScores']
  end

  def fairness_link
    link_to(get_fairness_service_url, id: "fairness-service-url", target: "_blank", "aria-label": t("get_json_version"), title: t("get_json_version")) do
      tag.img(src: asset_path('json.svg'), "aria-hidden" => "true", style: "margin-left: 0.5rem; width: 18px; margin-bottom: 4px;")
    end
  end
  

  def create_fair_scores_data(fair_scores, count = nil)
    return nil if fair_scores.nil?

    fair_scores_data = {}
    fair_scores_data[:principles] = {labels:[] , scores:[] , normalizedScores: [] , maxCredits: [] , portalMaxCredits: []}
    fair_scores_data[:criteria] = { labels:[] , scores:[] , normalizedScores: [] , portalMaxCredits: [], questions: [] ,maxCredits: [] , descriptions: []}
    fair_scores_data[:score] = fair_scores['score'].to_f.round(2)
    fair_scores_data[:normalizedScore] = fair_scores['normalizedScore'].to_f.round(2)
    fair_scores_data[:minScore] = fair_scores['minScore'].to_f.round(2)
    fair_scores_data[:maxScore] = fair_scores['maxScore'].to_f.round(2)
    fair_scores_data[:medianScore] = fair_scores['medianScore'].to_f.round(2)
    fair_scores_data[:maxCredits] = fair_scores['maxCredits'].to_i
    fair_scores_data[:resourceCount] = count unless  count.nil?

    fair_scores.to_h.select { |k,v| (v.is_a? Hash) }.each do |key, principle|

      fair_scores_data[:principles][:labels] << key
      fair_scores_data[:principles][:scores] << (principle['score'].to_f.round(2))
      fair_scores_data[:principles][:normalizedScores] << (principle['normalizedScore'].to_f.round(2))
      fair_scores_data[:principles][:maxCredits] << principle['maxCredits']
      fair_scores_data[:principles][:portalMaxCredits] << principle['portalMaxCredits']

      principle.to_h.select { |k,v| (v.is_a? Hash)  }.each do  |key , criterion|
        fair_scores_data[:criteria][:labels] << key
        fair_scores_data[:criteria][:descriptions] << criterion['label']
        fair_scores_data[:criteria][:scores] << (criterion['score'].to_f.round(2))
        fair_scores_data[:criteria][:normalizedScores] << (criterion['normalizedScore'].to_f.round(2))

        fair_scores_data[:criteria][:questions] << criterion['results']

        fair_scores_data[:criteria][:maxCredits] << criterion['maxCredits']
        fair_scores_data[:criteria][:portalMaxCredits] << criterion['portalMaxCredits']
      end
    end
    fair_scores_data
  end

  def get_not_obtained_score(fair_scores_data, index)
      fair_scores_data[:criteria][:portalMaxCredits][index] - fair_scores_data[:criteria][:scores][index]
  end

  def get_not_obtained_score_normalized(fair_scores_data, index)
    score_rest = get_rest_score(fair_scores_data,index)
    not_obtained_score = get_not_obtained_score(fair_scores_data , index)

    if  not_obtained_score.positive? && score_rest.positive?
      ((not_obtained_score / fair_scores_data[:criteria][:maxCredits][index]) * 100).round()
    elsif score_rest.zero?
        100 - fair_scores_data[:criteria][:normalizedScores][index]
    else
         0
    end

  end

  def get_rest_score(fair_scores_data, index)
    fair_scores_data[:criteria][:maxCredits][index] - fair_scores_data[:criteria][:portalMaxCredits][index]
  end

  def get_rest_score_normalized(fair_scores_data, index)
    score_rest = get_rest_score(fair_scores_data ,index)
    not_obtained_score_normalized = get_not_obtained_score_normalized(fair_scores_data , index)

    if score_rest.positive?
      100 - not_obtained_score_normalized - fair_scores_data[:criteria][:normalizedScores][index]
    else
      0
    end

  end

  def not_implemented?(question)
    properties = question['properties']
    score = question ['score']
    (properties.nil? || properties.empty?) && score.zero?
  end

  def default_score?(question)
    properties = question['properties']
    score = question ['score']

    (properties.nil? || properties.empty?) && score.positive?
  end

  def get_name_with_out_dot(name)
    name.to_s.gsub(/\./,'')
  end

  def print_score(score)
    number_with_precision(score, precision: 2, strip_insignificant_zeros: true)
  end
end

