#
# Data Source base class
#
module Dynosaur
  module Inputs
    class AbstractInputPlugin < Dynosaur::BasePlugin

      DEFAULT_HYSTERESIS_PERIOD = 300    # seconds we must be below threshold before reducing estimated dynos
      DEFAULT_INTERVAL = 60

      attr_reader :name, :unit, :last_retrieved_ts, :recent, :retrievals

      def initialize(config, controller)
        super(config)
        @controller = controller
        @unit = ""
        @value = nil
        @recent = RingBuffer.new(controller.buffer_size)
        @retrievals = 0
        @last_retrieved_ts = Time.at(0)
      end

      def retrieve
        raise NotImplementedError.new("You must define retrieve in your plugin")
      end

      def estimated_resources
        self.get_value # force refresh if @interval has run out
        recent_max = self.max_recent_values
        if recent_max.nil?
          return -1
        end
        return self.value_to_resources(recent_max) # call the implementation-specific conversion routine
      end

      def value_to_resources
        # Should that go here on in InputPlugin
        raise NotImplementedError.new("You must define value_to_resources in your controller")
      end

      def get_value
        now = Time.now
        if now > (@last_retrieved_ts + @controller.interval)
          begin
            @retrievals += 1
            @value = self.retrieve
            @last_retrieved_ts = now
          rescue Exception => e
            puts "Error in #{self.name}#retrieve : #{e.inspect}"
            ErrorHandler.report(e)
            @value = -1
          end
          # Store in the ringbuffer
          @recent << @value
        end
        return @value
      end

      def max_recent_values
        return @recent.max
      end

      def min_recent_values
        return @recent.min
      end

    end
  end
end
