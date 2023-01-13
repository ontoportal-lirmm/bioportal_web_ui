# frozen_string_literal: true

module ChangeRequestsHelper
  def change_request_success_message
    url = link_to 'details', @issue['url'], target: '_blank', class: 'alert-link'
    "Your change request was successfully submitted! View the #{url} on GitHub.".html_safe
  end

  def change_request_alert_context
    flash.notice.present? ? 'alert-success' : 'alert-danger'
  end
end
