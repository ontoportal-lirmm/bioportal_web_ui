module TurboHelper
  def frame_id(id, suffix)
    "#{id}_#{suffix}"
  end

  def alerts_container_id(id = nil)
    frame_id(id || controller_name, "alerts_container")
  end

  def alert(type: "success", &block)
    turbo_stream.prepend(alerts_container_id) do
      AlertMessageComponent.new(type: type).render_in(view_context, &block)
    end
  end

  def alert_error(&block)
    alert(type: "danger", &block)
  end

  def alert_success(&block)
    alert(type: "success", &block)
  end

  def prepend(id, options, &block)
    turbo_stream.prepend(id, options, &block)
  end

  def replace(id, options = {}, &block)
    turbo_stream.replace(id, options, &block)
  end

  def render_turbo_stream(*streams)
    render turbo_stream: streams
  end

  def render_alerts_container(controller_class = nil)
    render AlertsContainerComponent.new(id: alerts_container_id(controller_class&.controller_name))
  end
end
