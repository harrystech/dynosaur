
module Dynosaur
  module Controllers
    class DynosControllerPlugin < AbstractControllerPlugin
      DEFAULT_MIN_WEB_DYNOS = 2
      DEFAULT_MAX_WEB_DYNOS = 100

      attr_reader :min_resource, :max_resource

      def initialize(config)
        super(config)
        @min_resource = default_value_if_blank(config['min_resource'], DEFAULT_MIN_WEB_DYNOS).to_i
        @max_resource = default_value_if_blank(config['max_resource'], DEFAULT_MAX_WEB_DYNOS).to_i
      end

      def scale
        heroku_manager.ensure_value(@current_estimate)
      end

      def get_current_resource
        heroku_manager.get_current_value
      end

      def heroku_manager
        return @heroku_manager ||= HerokuDynoManager.new(@heroku_api_key, @heroku_app_name, @dry_run)
      end

    end # DynosControllerPlugin
  end # Controllers
end # Dynosaur
