# frozen_string_literal: true

class OntologySubscribeButtonComponent < ViewComponent::Base
  def initialize(ontology_id:, subscribed:, user_id:, count: 0, link: 'javascript:void(0);')
    super
    @subscribed = subscribed
    @sub_text = subscribed ? 'UnWatch' : 'Watch'
    @link = link
    @count = count
    @controller_params = {
      data: {
        controller: "tooltip #{!user_id.nil? && 'subscribe-notes'}",
        'subscribe-notes-ontology-id-value': ontology_id,
        'subscribe-notes-is-subbed-value': subscribed.to_s,
        'subscribe-notes-user-id-value': user_id,
        action: 'click->subscribe-notes#subscribeToNotes',
      },
      title: title
    }
  end

  def title
    if @subscribed
      "#{@sub_text} this resource"
    elsif @count.zero?
      "Be the first to watch this resource and  be notified of all its updates"
    else
      "Join the #{@count} users, watching this resource and  be notified of all its updates"
    end
  end
end
