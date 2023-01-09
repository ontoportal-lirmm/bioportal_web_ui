class SubscribeMailer < ApplicationMailer
    
    def register_for_announce_list(email,firstName,lastName)
      if subscription_configs_valid?
        if $ANNOUNCE_LIST_SERVICE.upcase.eql? "SYMPA"
          mail(
            :to => $ANNOUNCE_SERVICE_HOST, 
            :from => email, 
            :subject => "subscribe #{$ANNOUNCE_LIST} #{firstName} #{lastName}") 
          end  
        end
      end
       
    def unregister_for_announce_list(email)
      if subscription_configs_valid?
        if $ANNOUNCE_LIST_SERVICE.upcase.eql? "SYMPA"
          mail(
            :to => $ANNOUNCE_SERVICE_HOST, 
            :from => email, 
            :subject => "unsubscribe #{$ANNOUNCE_LIST}")
        end
      end  
    end
    

    private

    def subscription_configs_valid?
      $ANNOUNCE_SERVICE_HOST.present? &&  $ANNOUNCE_LIST_SERVICE.present? && $ANNOUNCE_LIST.present? 
    end
    
end
