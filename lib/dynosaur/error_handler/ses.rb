require 'aws-sdk-v1'

module Dynosaur::ErrorHandler
  class Ses < BaseHandler
    def initialize(config)
      @to = config[:to]
      @from = config[:from]
      @aws_access_key_id = config[:aws_access_key_id]
      @aws_secret_access_key = config[:aws_secret_access_key]

      if @to.blank? || @from.blank? || @aws_access_key_id.blank? || @aws_secret_access_key.blank?
        raise ArgumentError.new "Need to configure SES params"
      end

      @ses = AWS::SimpleEmailService.new(
        access_key_id: @aws_access_key_id,
        secret_access_key: @aws_secret_access_key)
      super
    end

    def handle(exception)
        puts "Reporting error to #{@to}"
        msg = "<div style='font-family: monospace;'>"
        msg += exception.message.to_s + "<br>"
        msg += exception.backtrace.join("<br>")
        msg += "</div>"

        @ses.send_email(
          from: @from,
          to: @to,
          subject: "Dynosaur Error",
          body_html: msg)
    end
  end

end
