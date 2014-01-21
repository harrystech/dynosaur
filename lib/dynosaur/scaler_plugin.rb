require 'dynosaur/error_handler'

# The base class for Dynosaur

class ScalerPlugin
  DEFAULT_INTERVAL = 60

  attr_reader :name, :unit, :interval, :last_retrieved_ts, :retrievals


  # Load some common config from the config json object
  # Sub-classes should override and call 'super'
  def initialize(config)
    @name = config["name"]
    if @name.nil?
      raise "You must specify a name"
    end
    @unit = ""
    @value = nil
    @interval = config.has_key?("interval") ? config["interval"] : DEFAULT_INTERVAL
    @retrievals = 0
    @last_retrieved_ts = Time.at(0)
  end

  # Abstract methods that must be declared on the subclass

  # retrieve: should connect to the API and return an integer
  def retrieve
    raise "ERROR: You must define estimated_dynos() in your plugin"
  end

  # estimated_dynos: should use the internal state to estimate how many dynos are currently required
  # Should return an integer.
  def estimated_dynos
    raise "ERROR: You must define estimated_dynos() in your plugin"
  end

  def self.get_config_template
    raise "ERROR: You must define get_config_template in your plugin"
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
    end
    return @value
  end

  # Requires Ruby 1.9
  # http://stackoverflow.com/questions/436159/how-to-get-all-subclasses
  def self.subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end


end
