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
end