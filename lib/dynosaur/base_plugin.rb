module Dynosaur
  class BasePlugin
    # Requires Ruby 1.9
    # http://stackoverflow.com/questions/436159/how-to-get-all-subclasses
    def self.subclasses
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def initialize(config)
      @name = config["name"]
      if @name.nil?
        raise "You must specify a name"
      end
    end
  end
end
