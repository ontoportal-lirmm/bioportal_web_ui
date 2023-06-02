# frozen_string_literal: true

class OntologySubscribeButtonComponent < ViewComponent::Base
  def initialize(ontology_id: , subscribed: , user_id:, count: 0, link:  'javascript:void(0);')
    super
    @sub_text = subscribed ? "UnWatch" : "Watch"
    @controller_params =  {
      data: {
        controller: 'subscribe-notes',
        'subscribe-notes-ontology-id-value':  ontology_id,
        'subscribe-notes-is-subbed-value': subscribed.to_s,
        'subscribe-notes-user-id-value':  user_id,
        action: 'click->subscribe-notes#subscribeToNotes'
      }
    }
    @link = link
    @count = count
  end
end
