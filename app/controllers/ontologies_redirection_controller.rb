module OntologiesRedirectionController
    include UriRedirection

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
    
    # GET /ontologies/htaccess/:acronym
    def generate_htaccess
        @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
        ontology_uri = @ontology.explore.latest_submission(include: 'URI').URI
        ontology_portal_uri = "#{$UI_URL}/ontologies/#{params[:acronym]}"
        rewriterule_ontology_uri = ""
        if ontology_uri
            ontology_uri += '/' unless ontology_uri.end_with?('/')
            rewriterule_ontology_uri = "RewriteRule ^#{URI.parse(ontology_uri).path[1..-1]}?$ #{ontology_portal_uri} [R=301,L]" 
            rewriterule_ontology_uri_nginx = "rewrite ^#{URI.parse(ontology_uri).path[1..-1]}?$ #{ontology_portal_uri} permanent"
        end

        @htaccess_content= <<-HTACCESS.strip_heredoc
            RewriteEngine On
            #{rewriterule_ontology_uri if rewriterule_ontology_uri}
            RewriteRule ^.*(?:/|#)([^/#]+)$ #{ontology_portal_uri}/$1 [R=301,L]
        HTACCESS

        @nginx_content=<<-NGINX.strip_heredoc
            location / {
                #{rewriterule_ontology_uri_nginx if rewriterule_ontology_uri_nginx}
                if ($request_uri ~ ^/(.*)/(?:|#)([^/#]+)$){
                    return 301 #{ontology_portal_uri}/$2;
                }
            }
        NGINX
        render 'ontologies/htaccess', layout: nil
    end
end