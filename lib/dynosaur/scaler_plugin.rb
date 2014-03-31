require 'dynosaur/error_handler'

# The base class for Dynosaur

class ScalerPlugin
  DEFAULT_INTERVAL = 60
  DEFAULT_HYSTERESIS_PERIOD = 300    # seconds we must be below threshold before reducing estimated dynos

  attr_reader :name, :unit, :interval, :last_retrieved_ts, :retrievals, :recent


  # Load some common config from the config json object
  # Sub-classes should override and call 'super'
  def initialize(config)
    @name = config["name"]
    if @name.nil?
      raise "You must specify a name"
    end
    @unit = ""
    @value = nil
    @interval = config.fetch("interval", DEFAULT_INTERVAL).to_i
    hysteresis_period = config.fetch("hysteresis_period", DEFAULT_HYSTERESIS_PERIOD).to_i
    buffer_size = hysteresis_period / @interval  # num intervals to keep
    @recent = RingBuffer.new(buffer_size)
    @retrievals = 0
    @last_retrieved_ts = Time.at(0)
  end

  # Abstract methods that must be declared on the subclass

  # retrieve: should connect to the API and return an integer
  def retrieve
    raise "ERROR: You must define estimated_dynos() in your plugin"
  end

  # estimated_dynos: use the internal state to estimate how many dynos are currently required
  # Should return an integer.
  #
  # If you are lazy, use this default implementation and just define
  # value_to_dynos()
  # If your plugin is more complicated (doesn't use @recent.max for example
  def estimated_dynos
    self.get_value # force refresh if @interval has run out
    recent_max = self.max_recent_values
    if recent_max.nil?
      return -1
    end
    return self.value_to_dynos(recent_max) # call the implementation-specific conversion routine
  end

  def value_to_dynos(value)
    raise "ERROR: You must define value_to_dynos in your plugin if you use default estimated_dynos()"
  end

  def self.get_config_template
    raise "ERROR: You must define get_config_template in your plugin"
  end

  def max_recent_values
    return @recent.max
  end

  def min_recent_values
    return @recent.min
  end

  # Get value (handles caching and API retrieval)
  def get_value
    now = Time.now
    if now > (@last_retrieved_ts + @interval)
      begin
        @retrievals += 1
        @value = self.retrieve
        @last_retrieved_ts = now
      rescue Exception => e
        puts "Error in #{self.name}#retrieve : #{e.inspect}"
        ErrorHandler.report_error(e)
        @value = -1
      end
      # Store in the ringbuffer
      @recent << @value
    end
    return @value
  end

  # Requires Ruby 1.9
  # http://stackoverflow.com/questions/436159/how-to-get-all-subclasses
  def self.subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end


end
