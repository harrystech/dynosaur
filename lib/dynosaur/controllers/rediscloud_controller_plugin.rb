module Dynosaur
  module Controllers
    class RediscloudControllerPlugin < AbstractControllerPlugin

      def initialize(config)
        super(config)
        min_resource_name = config.fetch('min_resource', Dynosaur::Addons.all['rediscloud'].first['name'])
        max_resource_name = config.fetch('max_resource', Dynosaur::Addons.all['rediscloud'].last['name'])
        @min_resource = AddonPlan.new(Dynosaur::Addons.plans_for_addon('rediscloud').find {|plan| plan['name'] == min_resource_name })
        if @min_resource.nil?
          raise "Min resource not found with name #{min_resource_name}"
        end
        @max_resource = AddonPlan.new(Dynosaur::Addons.plans_for_addon('rediscloud').find {|plan| plan['name'] == max_resource_name })
        if @max_resource.nil?
          raise "Max resource not found with name #{max_resource_name}"
        end
        @stats_callback = nil # We can't log this on librato as we don't have numeric values
      end

      def scale
        heroku_manager.ensure_value(@current_estimate['name'])
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
