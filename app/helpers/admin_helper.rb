module AdminHelper
  def selected_admin_section?(section_title)
    current_section = params[:section] || 'site'
    current_section.eql?(section_title)
  end


  def new_ontologies_created_title
    content_tag(:div,
                "The following ontologies: #{@new_ontologies_count.join(', ')} were created in this year",
                style: 'width: 400px; max-height: 300px')
  end
end
