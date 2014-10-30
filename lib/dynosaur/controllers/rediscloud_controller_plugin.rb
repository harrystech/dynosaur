module Dynosaur
  module Controllers
    class RediscloudControllerPlugin < AbstractControllerPlugin

      def initialize(config)
        super(config)
        @min_resource = config.fetch('min_resource', Dynosaur::Addons.plans_for_addon('rediscloud').first)
        @max_resource = config.fetch('max_resource', Dynosaur::Addons.plans_for_addon('rediscloud').last)
      end

      def scale
        heroku_manager.upgrade_addon(@current_estimate['name'])
      end

      def get_current_resource
        heroku_manager.get_current_plan
      end

      def heroku_manager
        return @heroku_manager ||= HerokuAddonManager.new('rediscloud', @heroku_api_key, @heroku_app_name, @dry_run)
      end

    end
  end # Controllers
end # Dynosaur
