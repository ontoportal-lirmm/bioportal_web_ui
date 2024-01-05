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

  def visits_evolution
    return 0 if @users_visits[:visits].empty?

    @users_visits[:visits].last - @users_visits[:visits][-2]
  end

  def action_button(name, link, method: :post, class_style: 'btn btn-link mb-3')
    button_to name, link, method: method, class: class_style,
                form: {data: { turbo: true, turbo_confirm: "Are you sure you want to #{name}?", turbo_frame: '_top'}}

  end
end
