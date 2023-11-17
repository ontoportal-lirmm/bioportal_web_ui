class Notifier < ApplicationMailer

  def error(error, current_user = nil, request_ip = nil)
    @error_message = error.message
    @backtrace = error.backtrace
    @current_user = current_user
    @request_ip = request_ip
  
    mail(to: "#{$SUPPORT_EMAIL}", from: "#{$SUPPORT_EMAIL}",
        subject: "[#{$SITE}] Exception Mailer: #{@error_message}")
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

end
