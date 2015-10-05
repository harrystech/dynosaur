
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
          handler.handle(exception)
        end
      end

      def handlers
        @@handlers ||= [Dynosaur::ErrorHandler::Console.new({})]
      end
    end

  end
end
