module InstancesHelper
  def get_instances_by_class_json(ontology_acronym, class_uri ,query_parameters)
    LinkedData::Client::HTTP
      .get("/ontologies/#{ontology_acronym}/classes/#{CGI.escape(class_uri)}/instances", query_parameters, raw: true)
  end

  def get_instances_by_ontology_json(ontology_acronym, query_parameters)
    LinkedData::Client::HTTP.get("/ontologies/#{ontology_acronym}/instances", query_parameters , raw:true)
  end

  def get_instance_details_json(ontology_acronym, instance_uri , query_parameters, raw = false )
    LinkedData::Client::HTTP
      .get("/ontologies/#{ontology_acronym}/instances/#{CGI.escape(instance_uri)}",
           query_parameters, raw: raw)
  end


  def get_instance_and_type(params)
    unless params[:instanceid].nil?
      instance_details = JSON.parse(get_instance_details_json(@ontology.acronym,params[:instanceid], {include: 'all'}, true ))
      types = instance_details['types'].reject{ |type| type.eql? 'http://www.w3.org/2002/07/owl#NamedIndividual'}

      [instance_details, types[0]]
    else
      [{},nil]
    end
  end

  # TODO: transfert this function to concepts helper and reuse where needed
  def conceptid_param_exist?(params)
    !(params[:conceptid].nil? || params[:conceptid].empty? || params[:conceptid].eql?("root") ||
      params[:conceptid].eql?("bp_fake_root"))
  end

  # TODO: transfert this function to concepts helper and reuse where needed
  def get_concept_id(params, concept, root)
    if conceptid_param_exist?(params)
      concept.nil? ? '' : concept.id
    elsif !root.children.first.nil?
      root.children.first.id
    end
  end
end