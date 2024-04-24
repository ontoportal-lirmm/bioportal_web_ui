# frozen_string_literal: true

module UriRedirection
    extend ActiveSupport::Concern

    include SearchContent
    
    def find_type_by_id(id, acronym)
        type, resource_id = find_type_by_search(id, acronym)
        return type, resource_id if type

        type, resource_id = find_type_by_metadata(id, acronym)
        return type, resource_id if type

        return nil, nil
    end

    def find_type_by_search(id, acronym)
        result = search_content(q: "*#{id}", qf: "resource_id", page: 1, pagesize: 10, ontologies: acronym)

        if result[:collection].empty?
          type = nil
          resource_id = nil
        else
          type = id_type(result[:collection][0][:type_t], result[:collection][0][:type_txt])
          resource_id = result[:collection][0][:resource_id]
        end
        [type, resource_id]
    end

    def find_type_by_metadata(id, acronym)
        return nil, nil # TODO maybe implimented if needed
    end

end  