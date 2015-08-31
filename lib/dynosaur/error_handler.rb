
require 'dynosaur/error_handler/base_handler'
require 'dynosaur/error_handler/console'
require 'dynosaur/error_handler/ses'

module Dynosaur
  module ErrorHandler
    class << self
      def initialize(config)
        if config.nil?
          config = [ { type: "Dynosaur::ErrorHandler::Console"} ]
        end

        @@handlers = []
        config.each do |handler_config|
          type = handler_config.with_indifferent_access.delete "type"
          handler = type.constantize.new(handler_config.with_indifferent_access)
          @@handlers << handler
        end
      end

      def handle(exception)
        @@handlers.each do |handler|
          handler.handle(exception)
        end
      end
    end

  end
end
