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
        result = search_content(q: "*##{id} || *\/#{id}", qf: "resource_id", page: 1, pagesize: 10, ontologies: acronym)

        find_exact_resource = result[:collection].select{|x| helpers.link_last_part(x[:resource_id]).eql?(id)}.first

        if !find_exact_resource
          type = nil
          resource_id = nil
        else
          type = id_type(find_exact_resource[:type_t], find_exact_resource[:type_txt])
          resource_id = find_exact_resource[:resource_id]
        end

        [type, resource_id]
    end

    def find_type_by_metadata(id, acronym)
        return nil, nil # TODO maybe implimented if needed
    end

end  