
# Dummy implementation of InputPlugin for testing
# Just returns random values and (value / 2) estimated dynos

module Dynosaur
  module Inputs
    class RandomPlugin < AbstractInputPlugin
      attr_reader :seed

      # Load config from the config json object
      def initialize(config)
        super(config)
        # stupid, kinda, but wanted to test plugin-specific options
        @seed = config["seed"].to_i # not even using it really
        @last =  45 + SecureRandom.random_number(10)
        @unit = "randoms"
      end

      def retrieve
        v = @last + SecureRandom.random_number(18) - 9
        v = 0 if v < 0
        puts "Generated new random int: #{v}"
        return v
      end

      def value_to_resources(value)
        return (value / 2.0).ceil
      end

    end
  end
end
