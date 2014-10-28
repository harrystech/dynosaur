
module Dynosaur
  module Controllers
    class DynosControllerPlugin < AbstractControllerPlugin
      DEFAULT_MIN_WEB_DYNOS = 2
      DEFAULT_MAX_WEB_DYNOS = 100

      attr_reader :min_resource, :max_resource

      def initialize(config)
        super(config)
        @min_resource = config.fetch('min_resource', DEFAULT_MIN_WEB_DYNOS)
        @max_resource = config.fetch('max_resource', DEFAULT_MAX_WEB_DYNOS)
      end

      def scale
        @heroku_manager.ensure_number_of_dynos(@current_estimate)
      end

    end # DynosControllerPlugin
  end # Controllers
end # Dynosaur
