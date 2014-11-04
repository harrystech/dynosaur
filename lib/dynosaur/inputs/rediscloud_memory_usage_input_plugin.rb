require 'dynosaur/new_relic_api_client'

module Dynosaur
  module Inputs
    class RediscloudMemoryUsageInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @unit = "memory usage (megabytes)"
        @max_percentage_threshold = config.fetch('max_percentage_threshold', 90.0).to_f
        @metric_name = "Component/redis/Used memory[megabytes]"

        # Get the list at https://api.newrelic.com/v2/components.json
        component_id = config['component_id'] # Some internal New Relic id
        @new_relic_api_client = Dynosaur::NewRelicApiClient.new(config['new_relic_api_key'], component_id)
      end

      def retrieve
        return get_memory_usage
      end

      def value_to_resources(value)
        return suitable_plans(value).first
      end

      def self.get_config_template
        {
          "max_percentage_threshold" => ["text"],
          "component_id" => ["text"],
          "new_relic_api_key" => ["text"],
        }
      end

      private

      def get_memory_usage
        return @new_relic_api_client.get_metric(@metric_name)
      end

      def suitable_plans(value)
        return plans.select{ |plan|
          plan["max_memory"] * (@max_percentage_threshold / 100) > value
        }.sort_by{ |plan|
          plan['max_memory']
        }
      end

      def plans
        Dynosaur::Addons.plans_for_addon('rediscloud')
      end

    end
  end # Inputs
end # Dynosaur
