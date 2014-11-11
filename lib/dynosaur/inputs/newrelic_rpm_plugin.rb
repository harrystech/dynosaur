require 'newrelic_api'
require 'dynosaur/version'
require 'dynosaur/error_handler'

# ScalerPlugin implementation that uses the New Relic API
# to get the current requests per minute on the site, and scale to an
# appropriate number of dynos.

module Dynosaur
  module Inputs
    class NewRelicPlugin < AbstractInputPlugin

      # Load config from the config hash
      def initialize(config)
        super
        @unit = "RPM"
        @key = config["key"]
        @appid = config["appid"].to_s
        @rpm_per_dyno = config["rpm_per_dyno"].to_i

        if @key.blank?
          raise "You must supply API key in the new relic plugin config"
        end
        if @appid.blank?
          raise "You must supply appid in the new relic plugin config"
        end
        init_api
      end

      def self.get_config_template
        t = {
          "appid" => ["text"],
          "key" => ["text"],
          "rpm_per_dyno" => ["text"]
        }
        return t
      end

      def retrieve
        return get_rpm
      end

      def value_to_resources(value)
        estimate = (value / @rpm_per_dyno.to_f).ceil
        Dynosaur.log "NEW RELIC: #{@recent} => #{value} : #{estimate}"
        return estimate
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
        if @newrelic_apps.empty?
          raise Exception.new "No matching newrelic app found for #{@appid}"
        end
      end

      def get_rpm
        rpm = -1
        begin
          @newrelic_apps.each do |newrelicapp|
            newrelicapp.threshold_values.each do |v|
              underscored_name = v.name.downcase.gsub(' ', '_')
              event_name = sprintf('%s_rpm_%s', newrelicapp.id, underscored_name)
              if event_name == "#{newrelicapp.id}_rpm_throughput"
                rpm = v.metric_value
              end
            end
          end
        rescue Exception => e
          ErrorHandler.report(e)
          Dynosaur.log "ERROR: failed to decipher New Relic result"
          Dynosaur.log e.inspect
        end
        return rpm
      end
    end
  end
end
