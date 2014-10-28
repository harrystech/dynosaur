module Dynosaur
  module Controllers
    class RediscloudControllerPlugin < AbstractControllerPlugin

      def initialize(config)
        super(config)
        @min_resource = config.fetch('min_resource', Dynosaur::Addons.plans_for_addon('rediscloud', 'max_memory').first)
        @max_resource = config.fetch('max_resource', Dynosaur::Addons.plans_for_addon('rediscloud', 'max_memory').last)
      end

      def scale
        heroku_manager.upgrade_addon('rediscloud', @current_estimate['name'])
      end

      def get_current_resource
        heroku_manager.get_current_plan('rediscloud')
      end

    end
  end # Controllers
end # Dynosaur
