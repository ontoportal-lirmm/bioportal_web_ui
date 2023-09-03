# frozen_string_literal: true

class Buttons::OntologySubscribeButtonComponentPreview < ViewComponent::Preview
  def default
    render OntologySubscribeButtonComponent.new(ontology_id: '', subscribed: true, user_id: '')
  end
end
