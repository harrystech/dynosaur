
module Dynosaur
  module Controllers
    class AbstractControllerPlugin < Dynosaur::BasePlugin

      attr_reader :input_plugins, :current_estimate, :current, :dry_run

      def initialize(config)
        super(config)

        # State variables
        @stopped = false
        @current_estimate = nil
        @current = nil
        @heroku_app_name = config['heroku_app_name']
        @heroku_api_key = config['heroku_api_key']
        @dry_run = config.fetch("dry_run", false)
        @last_results = {}
        @last_change_ts = nil

        load_input_plugins config['input_plugins']
      end

      def load_input_plugins(input_plugins_config)
        @input_plugins = []
        (input_plugins_config || []).each do |input_plugin_config|
          @input_plugins << load_input_plugin(input_plugin_config)
        end
      end

      def load_input_plugin(input_plugin_config)
        # Load the class and instantiate it
        begin
          klass = input_plugin_config['type'].constantize
          puts "Instantiating #{klass.name} for config '#{input_plugin_config["name"]}'"
          return klass.new(input_plugin_config)
        rescue NameError => e
          raise StandardError.new "Could not load #{input_plugin_config['type']}, #{e.message}"
        end
      end

      def heroku_manager
        raise NotImplementedError.new("You must define heroku_manager in your controller")
      end
      def get_combined_estimate
        estimates = []
        # Get the estimated dynos from all configured plugins
        @input_plugins.each { |plugin|
          estimates << plugin.estimated_resources
        }

        # Combine the estimates and mo
        combined_estimate = estimates.max

        combined_estimate = [@max_resource, combined_estimate].min
        combined_estimate = [@min_resource, combined_estimate].max

        return combined_estimate
      end

      def scale
        raise NotImplementedError.new("You must define scale in your controller")
      end

      def get_current_resource
        heroku_manager.get_current_value
      end

      def get_stats
      end

      def run
        before = get_current_resource
        @current_estimate = get_combined_estimate

        if @current_estimate != before
          scale
        end

        if before != @current_estimate
          puts "CHANGE: #{before} => #{@current_estimate}"
          @last_change_ts = Time.now
        end
        @current = @current_estimate
      end

      #
      # We don't have access to #blank? and it would be dumb to include activesupport
      # for only one method
      #
      # FIXME: just use config.fetch(name, default) instead of this
      # (make sure we're not setting empty strings!)
      def default_value_if_blank(value, default)
        # Stolen from: http://api.rubyonrails.org/classes/Object.html#method-i-blank-3F
        empty = value.respond_to?(:empty?) ? !!value.empty? : !value
        if empty
          return default
        else
          return value
        end
      end


    end # AbstractControllerPlugin
  end # Controllers
end # Dynosaur
