class OntologiesRedirectionController < ApplicationController
    include UriRedirection
    include OntologyContentSerializer

    # GET /ontologies/:acronym/:id
    def redirect
        return not_found unless params[:acronym] && params[:id]

        request_accept_header = request.env["HTTP_ACCEPT"].split(",")[0]
        type, resource_id  = find_type_by_id(params[:id], params[:acronym])

        if resource_id.nil?
            @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
            @submission_latest = @ontology.explore.latest_submission(include: "URI")
            resource_id = @submission_latest.URI
        end

        if request_accept_header == "text/html"
            if type.nil? || resource_id.blank?
                redirect_to ontology_path(id: params[:acronym], p: 'summary')
            else
                redirect_to link_by_type(resource_id, params[:acronym], type)
            end
        else
            content, serializer_content_type = serialize_content(ontology_acronym: params[:acronym], concept_id: resource_id, format: request_accept_header)
            render plain: content, content_type: serializer_content_type
        end
    end
    
    # GET /ontologies/:acronym/htaccess
    def generate_htaccess
        ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
        ontology_uri = ontology.explore.latest_submission(include: 'URI').URI
        ontology_portal_url = "#{$UI_URL}/ontologies/#{params[:acronym]}"
        
        @htaccess_content = generate_htaccess_content(ontology_portal_url, ontology_uri)
        @nginx_content = generate_nginx_content(ontology_portal_url, ontology_uri)

        render 'ontologies/htaccess', layout: nil
    end
    
    # GET /ontologies/ACRONYM/download?format=FORMAT
    def redirect_ontology
        redirect_url = "#{rest_url}/ontologies/#{params[:acronym]}"
        download_url = "#{redirect_url}/download?apikey=#{get_apikey}"
        case params[:format]
        when 'text/csv', 'csv'
          redirect_to("#{download_url}&download_format=csv",  allow_other_host: true)
        when 'text/xml', 'text/rdf+xml',  'application/rdf+xml', 'application/xml', 'xml'
          redirect_to("#{download_url}&download_format=rdf",  allow_other_host: true)
        when 'application/json', 'application/ld+json', 'application/*', 'json'
          # redirect to the api
          redirect_to("#{redirect_url}?apikey=#{get_apikey}", allow_other_host: true)
        else
          # redirect to download the original file 
          redirect_to("#{download_url}",  allow_other_host: true)
        end
    end
      
      
    private
      
    def generate_htaccess_content(ontology_portal_url, ontology_uri)
        ontology_rule = nil
        if ontology_uri
            ontology_uri += '/' unless ontology_uri.end_with?('/')
            ontology_rule = "RewriteRule ^#{URI.parse(ontology_uri).path[1..-1]}?$ #{ontology_portal_url} [R=301,L]"
        end

        <<-HTACCESS.strip_heredoc
            RewriteEngine On
            #{ontology_rule if ontology_rule}
            RewriteRule ^.*/([^/#]+)$ #{ontology_portal_url}/$1 [R=301,L]
        HTACCESS
    end
      
    def generate_nginx_content(ontology_portal_url, ontology_uri)
        ontology_rule = nil
        if ontology_uri
            ontology_uri += '/' unless ontology_uri.end_with?('/')
            ontology_rule = "rewrite ^#{URI.parse(ontology_uri).path[1..-1]}?$ #{ontology_portal_url} permanent"
        end
  
        <<-NGINX.strip_heredoc
            location / {
                #{ontology_rule if ontology_rule}
                if ($request_uri ~ ^.*/([^/]+)$){
                    return 301 #{ontology_portal_url}/$1;
                }
            }
        NGINX
    end
end