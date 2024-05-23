module SearchHelper
  def search_content_params
    query = params[:search].presence || '*'
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 100).to_i
    [query, page, page_size]
  end

  def render_search_paginated_list(container_id:, next_page_url:, child_url:, child_turbo_frame:,
                         child_param:, show_count: nil, lang: request_lang,
                         auto_click: false, results: , next_page: ,total_count: )
    query, page, _ = search_content_params

    @results = OpenStruct.new
    @results.nextPage = next_page
    @results.page = page
    @results.totalCount = total_count
    @results.collection = results.map { |x| o = OpenStruct.new(x); o.id = x[:name]; o }
    @results.collection = @results.collection.drop(1) # remove ontology
    @search = query

    next_page_link = next_page_url.include?('?') ? "#{next_page_url}&page=#{@results.nextPage}&search=#{@search}" : "#{next_page_url}?page=#{@results.nextPage}&search=#{@search}"
    next_page_link = "#{next_page_link}&lang=#{lang}"
    next_page_link = "#{next_page_link}&#{child_param}=#{escape(params[child_param.to_sym])}"
    selected = params[child_param.to_sym].blank? && page.eql?(1) ? @results.collection.first&.id : params[child_param.to_sym]

    if show_count && page.eql?(1)
      [
        replace("#{container_id}_count", content_tag(:span, @results.totalCount).html_safe),
        prepend("#{container_id}_view-page-1", paginated_list_component(id: container_id,
                                                                                        results: @results,
                                                                                        next_page_url: next_page_link,
                                                                                        child_url: child_url.include?('?') ? "#{child_url}&lang=#{lang}" : "#{child_url}?lang=#{lang}",
                                                                                        child_param: child_param,
                                                                                        child_turbo_frame: child_turbo_frame,
                                                                                        open_in_modal: show_count,
                                                                                        selected: selected))
      ]
    else
      render inline: paginated_list_component(id: container_id,
                                                      results: @results,
                                                      next_page_url: next_page_link,
                                                      child_url: child_url.include?('?') ? "#{child_url}&lang=#{lang}" : "#{child_url}?lang=#{lang}",
                                                      child_param: child_param,
                                                      child_turbo_frame: child_turbo_frame,
                                                      open_in_modal: show_count,
                                                      selected: selected,
                                                      auto_click: auto_click)
    end
  end
end