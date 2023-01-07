class SubscribeMailer < ApplicationMailer
    
    def register_for_announce_list(email,firstName,lastName)
      if are_subscription_configs_valid?
        mail(
          :to => $ANNOUNCE_SERVICE_HOST, 
          :from => email, 
          :subject => "subscribe #{$ANNOUNCE_LIST} #{firstName} #{lastName}") 
        end  
      end
       
    def unregister_for_announce_list(email)
      if are_subscription_configs_valid?
        mail(
          :to => $ANNOUNCE_SERVICE_HOST, 
          :from => email, 
          :subject => "unsubscribe #{$ANNOUNCE_LIST}")    
      end  
    end
    

    private

    def are_subscription_configs_valid?
      $ANNOUNCE_LIST.present? &&  $ANNOUNCE_LIST_SERVICE.present? && $ANNOUNCE_LIST.present? 
    end
    
end
