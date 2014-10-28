module Dynosaur
  module Controllers
    class RediscloudControllerPlugin < AbstractControllerPlugin

      def initialize(config)
        super(config)
        # ...
      end

      def scale
        # Use heroku platform api to switch plan
        # @current_estimate is the plan
        # @current_estimate
      end

    end
  end # Controllers
end # Dynosaur
