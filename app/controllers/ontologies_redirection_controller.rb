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
        subminssions_params = ontology.explore.latest_submission(include: 'URI,preferredNamespaceUri')
        ontology_uri = subminssions_params.URI
        preferred_name_space_uri = subminssions_params.preferredNamespaceUri
        ontology_portal_url = "#{$UI_URL}/ontologies/#{params[:acronym]}"
        
        @htaccess_content = generate_htaccess_content(ontology_portal_url, ontology_uri, preferred_name_space_uri)
        @nginx_content = generate_nginx_content(ontology_portal_url, ontology_uri, preferred_name_space_uri)

        render 'ontologies/htaccess', layout: nil
    end

    # GET /ontologies/ACRONYM/download?format=FORMAT
    def redirect_ontology
        download_ontology(params)
    end
      
      
    private
      
    def generate_htaccess_content(ontology_portal_url, ontology_uri, preferred_name_space_uri)
        preferred_name_space_path = get_path(preferred_name_space_uri)
        ontology_uri_path = get_path(ontology_uri)
        
        rewrite_condition = if preferred_name_space_path
                              "RewriteCond %{REQUEST_URI} ^.*#{preferred_name_space_path}.*$"
                            elsif ontology_uri_path
                              "RewriteCond %{REQUEST_URI} ^.*#{ontology_uri_path}.*$"
                            end
        
        ontology_rule = if ontology_uri_path
                          ontology_uri_path += '/' unless ontology_uri_path.end_with?('/')
                          "RewriteRule ^#{ontology_uri_path}?$ #{ontology_portal_url} [R=301,L]"
                        end
      
        <<-HTACCESS.strip_heredoc
          RewriteEngine On
          #{ontology_rule if ontology_rule}
          #{rewrite_condition if rewrite_condition}
          RewriteRule ^.*/([^/#]+)/?$ #{ontology_portal_url}/$1 [R=301,L]
        HTACCESS
    end
      
    def generate_nginx_content(ontology_portal_url, ontology_uri, preferred_name_space_uri)
        preferred_name_space_path = get_path(preferred_name_space_uri)
        ontology_uri_path = get_path(ontology_uri)
        
        rewrite_condition = preferred_name_space_path || ontology_uri_path

        ontology_rule = if ontology_uri_path
                            ontology_uri_path += '/' unless ontology_uri_path.end_with?('/')
                            ontology_rule = "rewrite ^/#{ontology_uri_path}?$ #{ontology_portal_url} permanent;"
                        end
  
        <<-NGINX.strip_heredoc
            location / {
                #{ontology_rule if ontology_rule}
                if ($request_uri ~* #{rewrite_condition} ){
                    rewrite ^.*/([^/]+)/?$ #{ontology_portal_url}/$1 permanent;
                }
            }
        NGINX
    end
    
    def get_path(uri)
        begin
          parsed_uri = URI.parse(uri)
          parsed_uri.path[1..-1]
        rescue URI::InvalidURIError
          nil
        end
    end

end