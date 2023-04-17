class Notifier < ApplicationMailer

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

  def feedback(name, email, comment, location, tags)
    @name = name
    @email = email
    @comment = comment
    @location = location
    @tags = tags

    mail(:to => "#{$SUPPORT_EMAIL}, #{email}",
         :from => "#{$SUPPORT_EMAIL}",
         :subject => "[#{$SITE}] Feedback from #{name}")
  end

  def signup(user)

  end

end
