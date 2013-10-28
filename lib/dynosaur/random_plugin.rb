
# Dummy implementation of ScalerPlugin for testing
# Just returns random values and (value / 2) estimated dynos

class RandomPlugin < ScalerPlugin
    attr_reader :seed

    # Load config from the config json object
    def initialize(config)
        super
        # stupid, kinda, but wanted to test plugin-specific options
        @seed = config["seed"].to_i # not even using it really
        @unit = "randoms"
    end

    def retrieve
        v = SecureRandom.random_number(100)
        puts "Generated new random int: #{v}"
        return v
    end

    def estimated_dynos
        @value = self.get_value
        if @value.nil?
            return -1
        end
        return (@value / 2.0).ceil
    end


end
