class Notifier < ActionMailer::Base
  def signup(user)
  end

  def lost_password(user, password)
    # Email header info MUST be added here
    recipients user.email
    from "#{$SUPPORT_EMAIL}"
    subject "[#{$ORG_SITE}] Password Reset"

    # Email body substitutions go here
    body :user => user, :password => password
  end

  def error(error)
    recipients $ERROR_EMAIL
    from "#{$ADMIN_EMAIL}"
    subject "Exception Mailer"
    body :exception_message => error.message, :trace => error.backtrace
  end

  def endlessloop(node)
    recipients $ERROR_EMAIL
    from "#{$ADMIN_EMAIL}"
    subject "Exception Mailer"
    body :node => node.inspect
  end

  def feedback(name, email, comment, location = "")
    @name = name
    @email = email
    @comment = comment
    @location = location

    mail(:to => "#{$SUPPORT_EMAIL}, #{email}",
         :from => "#{$SUPPORT_EMAIL}",
         :subject => "[#{$SITE}] Feedback from #{name}")
  end

  def register_for_announce_list(email)
    unless $ANNOUNCE_LIST.nil? || $ANNOUNCE_LIST.empty?
      recipients "#{$ANNOUNCE_LIST}"
      from "#{$ADMIN_EMAIL}"
      subject "subscribe address=#{email}"
    end
  end
end
