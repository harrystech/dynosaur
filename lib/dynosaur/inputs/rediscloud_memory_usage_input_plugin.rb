
module Dynosaur
  module Inputs
    class RediscloudMemoryUsageInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @unit = "memory usage percentage"
        @min_percentage_threshold = 10.0
        @max_percentage_threshold = 90.0
        @new_relic_api_key = config['new_relic_api_key']
        # Get the list at https://api.newrelic.com/v2/components.json
        @component_id = config['component_id'] # Some internal New Relic id
        @metric_name = "Component/redis/Memory usage[%]"
      end

      def retrieve
        return get_memory_usage
      end

      def value_to_resources(value)
        return AddonPlan.new(suitable_plans(value).first, 'max_memory')
      end

      private

      def get_memory_usage
        api_path = "/v2/components/#{@component_id}/metrics/data.json"
        response = faraday_connection.post(api_path) do |req|
          req.headers['X-Api-Key'] = @new_relic_api_key
          req.body = {
            'names[]' => "Component/redis/Used memory[megabytes]",
            'values[]' => 'average_value',
            'summarize' => true,
          }
        end
        response_data = JSON.parse(response.body)
        return response_data['metric_data']['metrics'][0]['timeslices'][0]['values']['average_value']
      end

      def faraday_connection
        base_url = "https://api.newrelic.com"
        conn = Faraday.new(:url => base_url) do |faraday|
          faraday.request :url_encoded
          faraday.response :logger
          faraday.adapter  Faraday.default_adapter
        end
      end

      def suitable_plans(value)
        return plans.select{ |plan|
          plan["max_memory"] * (@max_percentage_threshold / 100) > value
        }.sort_by{ |plan|
          plan['max_memory']
        }
      end

      def plans
        Psych.load(plan_file('rediscloud'))['dynosaur']['addons']['rediscloud']
      end

      def plan_file(addon_name)
        File.read(File.join('lib/dynosaur/addons/plans/', "#{addon_name}.yml"))
      end

    end
  end # Inputs
end # Dynosaur
