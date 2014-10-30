require 'dynosaur/papertrail_api_client'
require 'time'

module Dynosaur
  module Inputs
    class PapertrailInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @unit = "log volume (bytes)"
        @max_percentage_threshold = config.fetch('max_percentage_threshold', 90.0)

        # By far not the most memory efficient strategy as the log volumen will
        # always increase during the day we don't need all the historical data
        # But that allows us to use the default hysteresis logic
        hysteresis_period = 86400 # We want to use the entire day
        @buffer_size = hysteresis_period / @interval  # num intervals to keep
        @recent = RingBuffer.new(@buffer_size)

        @papertrail_api_client = Dynosaur::PapertrailApiClient.new(config['papertrail_api_key'])
      end

      def retrieve
        get_log_volume
      end

      def get_value
        today = Time.now.utc.day
        if (Time.now.utc - @interval).day == today - 1
          puts "Resetting historic data for the past day, and starting fresh."
          @recent.clear
        end
        super
      end

      def value_to_resources(value)
        return AddonPlan.new(suitable_plans(value).first)
      end

      def self.get_config_template
        {
          "max_percentage_threshold" => ["text"],
          "papertrail_api_key" => ["text"],
        }
      end

      private

      def get_log_volume
        @papertrail_api_client.get_daily_usage
      end

      def suitable_plans(value)
        return plans.select{ |plan|
          plan["max_log_volume"] * (@max_percentage_threshold / 100) > value
        }.sort_by{ |plan|
          plan['max_log_volume']
        }
      end

      def plans
        # TODO: Use Dynosaur::Addons instead
        Psych.load(plan_file('papertrail'))['dynosaur']['addons']['papertrail']
      end

      def plan_file(addon_name)
        # TODO: Use Dynosaur::Addons instead
        File.read(File.join('lib/dynosaur/addons/plans/', "#{addon_name}.yml"))
      end

    end
  end # Inputs
end # Dynosaur
