module Dynosaur
  class HerokuAddonManager < HerokuManager

    attr_reader :addon_name

    def initialize(addon_name, app_name, api_key, dry_run)
      super(app_name, api_key, dry_run)
      @addon_name = addon_name
    end

    def retrieve
      return get_current_plan
    end

    def set(value)
      if get_current_plan['id'].nil?
        raise "Addon: #{@addon_name} is not provisionned on app : #{@app_name}"
      end

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
      plan_list = @heroku_platform_api.plan.list('rediscloud')
      return plan_list.find { |plan| plan['name'] == value }['id']
    end

  end
end
