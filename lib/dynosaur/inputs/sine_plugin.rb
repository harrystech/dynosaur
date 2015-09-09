
# Dummy implementation of ScalerPlugin for testing
# Just returns sine values and value = dynos estimates

module Dynosaur
  module Inputs
    class SinePlugin < AbstractInputPlugin
      attr_reader :period

      # Load config from the config json object
      def initialize(config)
        super
        # stupid, kinda, but wanted to test plugin-specific options
        @period = config.fetch("period", 30).to_f
        @t0 = Time.now
        @unit = "dynos"
      end

      def retrieve
        omega = 2*3.14/@period
        t = Time.now - @t0
        v = (Math.sin(omega*t) + 1)*50  # sine between 0 and 20
        return v.ceil
      end

      def value_to_resources(value)
        estimate = (value/10.0).ceil
        puts "SINE: #{@recent} => #{value} : #{estimate}"
        return estimate
      end
    end
  end
end
