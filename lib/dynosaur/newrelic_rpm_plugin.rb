require 'newrelic_api'
require 'dynosaur/version'
require 'dynosaur/error_handler'

# ScalerPlugin implementation that uses the New Relic API
# to get the current active users on the site, and scale to an
# appropriate number of dynos.

class NewRelicPlugin < ScalerPlugin
  attr_reader :seed
  KEY = 'notasecret'

  # Load config from the config hash
  def initialize(config)
    super
    @unit = "active users"
    @key = config.fetch("key", KEY)
    @appid = config["appid"]
    @users_per_dyno = config["users_per_dyno"].to_i

    if @appid.nil?
      raise "You must supply appid in the new relic plugin config"
    end
    init_api
  end

  def self.get_config_template
    t = {
      "appid" => ["text"],
      "key" => ["text"],
      "users_per_dyno" => ["text"]
    }
    return t
  end

  def retrieve
    return get_active_users
  end

  def estimated_dynos
    @value = self.get_value
    if @value.nil?
      return -1
    end
    return (@value / @users_per_dyno.to_f).ceil
  end

  private
  def init_api
    app_ids = [@appid]
    NewRelicApi.api_key = @key
    newrelic_account = NewRelicApi::Account.find(:first)
    # Prepared for future support of multiple apps
    @newrelic_apps = newrelic_account.applications.select do |app|
      app_ids.include? app.id.to_s if app_ids
    end
  end

  def get_active_users
    active = -1
    begin
      @newrelic_apps.each do |newrelicapp|
        newrelicapp.threshold_values.each do |v|
          underscored_name = v.name.downcase.gsub(' ', '_')
          event_name = sprintf('%s_rpm_%s', newrelicapp.id, underscored_name)
          if event_name == "#{newrelicapp.id}_rpm_throughput"
            active = v.metric_value
          end
        end
      end
    rescue Exception => e
      ErrorHandler.report(e)
      puts "ERROR: failed to decipher result, forcing re-auth"
      puts e.inspect
    end
    return active
  end
end
