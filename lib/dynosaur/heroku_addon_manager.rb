module Dynosaur
  class HerokuAddonManager < HerokuManager

    attr_reader :addon_name

    def initialize(addon_name, app_name, api_key, dry_run)
      super(app_name, api_key, dry_run)
      @addon_name = addon_name
      @current_value = nil
    end

    def retrieve
      plan_name = get_current_plan['name']
      plans = Dynosaur::Addons.plans_for_addon(@addon_name)
      current_plan = plans.find { |plan| plan['name'] == plan_name }
      return current_plan
    end

    def set(plan)
      if !@dry_run
        @heroku_platform_api.addon.update(@app_name, addon_id, {plan: get_plan_id(plan)})
      end
      @current_value = plan
    end

    def addon_id
      return @addon_id ||= current_addon['id']
    end

    def current_addon
      if @current_addon.nil?
        addons = @heroku_platform_api.addon.list(@app_name)
        @current_addon = addons.find { |addon| addon['addon_service']['name'] == @addon_name }
      end
      return @current_addon
    end

    def get_current_plan
      return current_addon['plan']
    end

    def get_plan_id(plan)
      if @plans.nil?
        @plans = @heroku_platform_api.plan.list(@addon_name)
      end
      plan_name = plan['name']
      return @plans.find { |plan| plan['name'] == plan_name }['id']
    end

  end
end
