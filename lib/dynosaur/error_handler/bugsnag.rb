require 'bugsnag'

module Dynosaur::ErrorHandler
  class Bugsnag < BaseHandler
    def initialize(config)
      ::Bugsnag.configure do |bugsnag_config|
        bugsnag_config.api_key = config[:api_key]
      end
      super
    end

    def handle(exception)
      ::Bugsnag.notify(exception)
    end
  end
end
