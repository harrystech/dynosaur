
module Dynosaur
  module Controllers
    class DynosControllerPlugin < AbstractControllerPlugin
      DEFAULT_MIN_WEB_DYNOS = 2
      DEFAULT_MAX_WEB_DYNOS = 100

      attr_reader :min_web_dynos, :max_web_dynos

      def initialize(config)
        super(config)
        @min_web_dynos = config.fetch('min_web_dynos', DEFAULT_MIN_WEB_DYNOS)
        @max_web_dynos = config.fetch('max_web_dynos', DEFAULT_MAX_WEB_DYNOS)
      end

      def scale
        @heroku_manager.ensure_number_of_dynos(@current_estimate)
      end

    end # DynosControllerPlugin
  end # Controllers
end # Dynosaur
