class SubscriptionsController < ApplicationController

  def create
    # Try to get the user linked data instance
    user_id = params[:user_id]
    u = LinkedData::Client::Models::User.find(user_id)
    raise Exception if u.nil?

    # Try to get the ontology linked data instance
    ontology_id = params[:ontology_id]
    if ontology_id.start_with? 'http'
      ont = LinkedData::Client::Models::Ontology.find(ontology_id)
    else
      ont = LinkedData::Client::Models::Ontology.find_by_acronym(ontology_id).first
    end
    raise Exception if ont.nil?

    # Is this request to add or remove a subscription?
    subscribed = params[:subbed]  # string (not boolean)
    if subscribed.eql?("true")
      # Already subscribed, so this request must be a delete
      # Note that this routine removes ALL subscriptions for the ontology, regardless of type.
      # Previous way to delete subscription: error when u.update if more than 1 subscription in the subscription array:
      #u.subscription.delete_if {|sub| sub[:ontology].split('/').last.eql?(ont.acronym) }
      # So here we re-generate a new subscription Array (instead of directly updating it, which causes error)
      all_subs = []
      u.subscription.each do |subs|
        # Add all subscription to the array, but not the one to be deleted
        if !subs.ontology.split('/').last.eql?(ont.acronym)
          all_subs.push({ontology: subs.ontology, notification_type: subs.notification_type})
        end
      end
      u.subscription = all_subs
    else
      # Not subscribed yet, so this request must be for adding subscription
      # Old way:
      #subscription = {ontology: ont.acronym, notification_type: "NOTES"} #NOTIFICATION_TYPES[:notes]}
      #u.subscription.push(subscription)
      # This way was not working, updating subscription is failing when more than 1 subscription in the array
      # And we were updating with different types of object in the subscription array : OpenStruct and hash
      # So we are generating an array with only hash
      already_subscribed = false
      all_subs = []
      u.subscription.each do |subs|
        # add all existing subscriptions
        all_subs.push({ontology: subs.ontology, notification_type: subs.notification_type})
        if subs.ontology.split("/").last == ont.acronym && subs.notification_type == "NOTES"
          # avoid to subscribe many times to the same ontology
          already_subscribed = true
        end
      end
      if already_subscribed == false
        all_subs.push({ontology: ont.acronym, notification_type: "NOTES"})  # the new subscription
      end
      u.subscription = all_subs
    end

    # Try to update the user instance and the session user.
    begin
      error_response = u.update
      if response_success?(error_response)
        updated_sub = true
        session[:user].subscription = u.subscription
        #session[:user] = u
        # NOTES:
        # - Cannot update session[:user] as above.  The session user object is special because it only
        #   gets set when someone logs in and the user object returned when authenticating is the
        #   only one that will contain the api key for security reasons. So we actually need to use
        #   the update_from_params method, can’t just set the object to the user linked data instance.
        #
        #session[:user].update_from_params(params[:user])
        # update_from_params first gets all attributes from the REST service for the object being updated,
        # then sets the values provided in the params hash where the param keys match setter names on the
        # object (in this case, for example, :subscription would set the @subscription value on the instance).
        # That’s all it does, no saving or anything.
      else
        updated_sub = false
        #errors = response_errors(error_response)
      end
    rescue
      updated_sub = false
    end

    render :json => { :updated_sub => updated_sub, :user_subscriptions => u.subscription }
  end

end
