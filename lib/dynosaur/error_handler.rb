
require 'dynosaur/error_handler/base_handler'
require 'dynosaur/error_handler/console'
require 'dynosaur/error_handler/ses'
require 'dynosaur/error_handler/bugsnag'

module Dynosaur
  module ErrorHandler
    class << self
      def initialize(config)
        return if config.nil?
        @@handlers = []
        config.each do |handler_config|
          type = handler_config.with_indifferent_access.delete "type"
          handler = type.constantize.new(handler_config.with_indifferent_access)
          @@handlers << handler
        end
      end

      def handle(exception)
        handlers.each do |handler|
          begin
            handler.handle(exception)
          rescue StandardError => e
            puts "Error handler caused an error! Now we're in trouble"
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
      end

      def handlers
        @@handlers ||= [Dynosaur::ErrorHandler::Console.new({})]
      end
    end

  end
end
