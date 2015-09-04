
module Dynosaur
  module Inputs
    class RediscloudRandomInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @max_percentage_threshold = 90.0
        @unit = "randoms"
      end

      def retrieve
        max_value = (50000 * @max_percentage_threshold / 100).to_i
        v = SecureRandom.random_number(max_value)
        puts "Generated new random int: #{v}"
        return v
      end

      def value_to_resources(value)
        return suitable_plans(value).first
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
