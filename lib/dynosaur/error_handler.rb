
require 'mail'

module ErrorHandler
  class << self
    def initialize
      Dynosaur.log "Initializing default error handler"
      @has_mail = false
      @smtp_host = "smtp.sendgrid.net"
      @smtp_port = 587
      @smtp_domain = "heroku.com"
      @smtp_user_name = ENV['SENDGRID_USERNAME']
      @smtp_password = ENV['SENDGRID_PASSWORD']
      @report_address = ENV["DYNOSAUR_ADMIN_EMAIL"]

      if !@smtp_user_name.nil? && !@smtp_password.nil? && !@report_address.nil?
        @has_mail = true
        Dynosaur.log "Errors will be emailed to #{@report_address}"
        Mail.defaults do
          delivery_method :smtp, {
            :address => 'smtp.sendgrid.net',
            :port => '587',
            :domain => 'heroku.com',
            :user_name => ENV['SENDGRID_USERNAME'],
            :password => ENV['SENDGRID_PASSWORD'],
            :authentication => :plain,
            :enable_starttls_auto => true
          }
        end
      end
    end

    def report(exception)
      begin
        Dynosaur.log "========= ERROR ==========="
        Dynosaur.log exception.message
        Dynosaur.log exception.backtrace.join("\n")
        Dynosaur.log "Sleeping for #{@interval} before re-entering loop"
        if @has_mail.nil? || !@has_mail
          return
        end

        to = @report_address
        Dynosaur.log "Reporting error to #{to}"
        msg = "<div style='font-family: monospace;'>"
        msg += exception.message.to_s + "<br>"
        msg += exception.backtrace.join("<br>")
        msg += "</div>"

        mail = Mail.new do
          from 'dynosaur@harrys.com'
          to    to
          subject 'Dynosaur exception'

          html_part do
            body msg
          end
        end

        Dynosaur.log mail.to_s
        mail.deliver!

      rescue Exception => e
        Dynosaur.log "Oh man, error sending error email!"
        Dynosaur.log e.message
        Dynosaur.log e.backtrace.join("\n")
      end

    end
  end
end
