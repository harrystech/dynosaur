module Dynosaur
  class HerokuAddonManager < HerokuManager

    attr_reader :addon_name

    def initialize(addon_name, app_name, api_key, dry_run)
      super(app_name, api_key, dry_run)
      @addon_name = addon_name
    end

    def retrieve
      return get_current_plan['name']
    end

    def set(value)
      if !@dry_run
        @heroku_platform_api.addon.update(@app_name, @addon_name, {plan: get_plan_id(value)})
      end
      @current_value = value
    end

    def get_current_plan
      addons = @heroku_platform_api.addon.list(@app_name)
      return addons.find { |addon| addon['name'] == @addon_name }['plan']
    end

    def get_plan_id(value)
      if @plans.nil?
        puts "HITTING THE API: HerokuAddonManager#get_plan_id"
        @plans = @heroku_platform_api.plan.list(@addon_name)
      end
      return @plans.find { |plan| plan['name'] == value }['id']
    end

  end
end
