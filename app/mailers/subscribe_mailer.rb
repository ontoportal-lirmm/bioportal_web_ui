class SubscribeMailer < ApplicationMailer
    
    def register_for_announce_list(email,firstName,lastName)
        unless $ANNOUNCE_LIST.nil? || $ANNOUNCE_LIST.empty?
          if $ANNOUNCE_LIST_SERVICE.upcase.eql? "SYMPA"
            mail(:to => $ANNOUNCE_SERVICE_HOST, 
              :from => email, 
              :subject => "subscribe #{$ANNOUNCE_LIST} #{firstName} #{lastName}")    
          end   
        end
      end
    
      def unregister_for_announce_list(email)
        unless $ANNOUNCE_LIST.nil? || $ANNOUNCE_LIST.empty?
          if $ANNOUNCE_LIST_SERVICE.upcase.eql? "SYMPA"
            mail(:to => $ANNOUNCE_SERVICE_HOST, 
              :from => email, 
              :subject => "unsubscribe #{$ANNOUNCE_LIST}",
              :body => "")    

            end   
        end
      end
    
end
