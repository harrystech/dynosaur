#
# Data Source base class
#
module Dynosaur
  module Inputs
    class AbstractInputPlugin < Dynosaur::BasePlugin

      DEFAULT_INTERVAL = 60
      DEFAULT_HYSTERESIS_PERIOD = 300    # seconds we must be below threshold before reducing estimated dynos
      DEFAULT_OUTAGE_PERIOD = 300        # seconds since we got a good reading (we report the outage otherwise)

      attr_reader :name, :unit, :last_retrieved_ts, :recent, :retrievals, :buffer_size, :interval

      def initialize(config)
        super(config)
        @unit = ""
        @value = nil
        @retrievals = 0
        @last_retrieved_ts = Time.at(0)
        @interval = config.fetch("interval", DEFAULT_INTERVAL).to_f
        hysteresis_period = config.fetch("hysteresis_period", DEFAULT_HYSTERESIS_PERIOD).to_f
        @buffer_size = hysteresis_period / @interval  # num intervals to keep
        @recent = RingBuffer.new(@buffer_size)
      end

      def retrieve
        raise NotImplementedError.new("You must define retrieve in your plugin")
      end

      def estimated_resources
        self.get_value # force refresh if @interval has run out
        recent_max = self.max_recent_values
        return self.value_to_resources(recent_max) # call the implementation-specific conversion routine
      end

      def value_to_resources(value)
        raise NotImplementedError.new("You must define value_to_resources in your controller")
      end

      def get_value
        now = Time.now
        # binding.pry
        if now > (@last_retrieved_ts + @interval)
          @value = do_retrievals
        end
        return @value
      end

      def do_retrievals
        begin
          @retrievals += 1
          @value = self.retrieve
          @last_retrieved_ts = Time.now
        rescue StandardError => e
          puts "Error in #{self.name}#retrieve : #{e.inspect}"
          Dynosaur::ErrorHandler.handle(e)
          @value = -1
        end
        # Store in the ringbuffer
        @recent << @value
        return @value
      end

      def max_recent_values
        return @recent.max
      end

      def min_recent_values
        return @recent.min
      end

      def health
        now = Time.now
        current_health = "OK"
        if now - @last_retrieved_ts > @interval
          current_health = "STALE"
        end
        if now - @last_retrieved_ts > DEFAULT_OUTAGE_PERIOD
          current_health = "OUTAGE"
        end
        current_health
      end
    end
  end
end
