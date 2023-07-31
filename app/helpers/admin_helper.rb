module AdminHelper
  def selected_admin_section?(section_title)
    current_section = params[:section] || 'site'
    current_section.eql?(section_title)
  end
end
