
module Dynosaur
  module Controllers
    class PapertrailControllerPlugin < AbstractControllerPlugin

      def initialize(config)
        super(config)
        min_resource_name = config.fetch('min_resource', Dynosaur::Addons.all['papertrail'].first['name'])
        max_resource_name = config.fetch('max_resource', Dynosaur::Addons.all['papertrail'].last['name'])
        @min_resource = Dynosaur::Addons.plans_for_addon('papertrail').find {|plan| plan['name'] == min_resource_name }
        @max_resource = Dynosaur::Addons.plans_for_addon('papertrail').find {|plan| plan['name'] == max_resource_name }
      end

      def scale
        heroku_manager.ensure_value(@current_estimate['name'])
      end

      def get_current_resource
        heroku_manager.get_current_plan
      end

      def heroku_manager
        return @heroku_manager ||= HerokuAddonManager.new('papertrail', @heroku_api_key, @heroku_app_name, @dry_run)
      end

    end
  end # Controllers
end # Dynosaur