require 'dynosaur/new_relic_api_client'

module Dynosaur
  module Inputs
    class RediscloudMemoryUsageInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @unit = "memory usage (megabytes)"
        @min_percentage_threshold = 10.0
        @max_percentage_threshold = 90.0
        @metric_name = "Component/redis/Used memory[megabytes]"

        # Get the list at https://api.newrelic.com/v2/components.json
        component_id = config['component_id'] # Some internal New Relic id
        @new_relic_api_client = Dynosaur::NewRelicApiClient.new(config['new_relic_api_key'], component_id)
      end

      def retrieve
        return get_memory_usage
      end

      def value_to_resources(value)
        return AddonPlan.new(suitable_plans(value).first)
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
        # TODO: Use Dynosaur::Addons instead
        Psych.load(plan_file('rediscloud'))['dynosaur']['addons']['rediscloud']
      end

      def plan_file(addon_name)
        # TODO: Use Dynosaur::Addons instead
        File.read(File.join('lib/dynosaur/addons/plans/', "#{addon_name}.yml"))
      end

    end
  end # Inputs
end # Dynosaur
