require 'librato/metrics'

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
        @librato_email = config['librato_email']
        @librato_api_key = config['librato_api_key']
        @dry_run = config.fetch("dry_run", false)
        @stats_callback = self.method(:librato_send) # default built-in stats callback
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
        # Load the class and instanciate it
        begin
          klass = Kernel.const_get(input_plugin_config['type'])
          puts "Instantiating #{klass.name} for config '#{input_plugin_config["name"]}'"
          return klass.new(input_plugin_config)
        rescue NameError => e
          raise "Could not load #{input_plugin_config['type']}, #{e.message}"
        end
      end

      def heroku_manager
        raise NotImplementedError.new("You must define heroku_manager in your controller")
      end

      def get_combined_estimate
        estimates = []
        details = {}
        # Get the estimated dynos from all configured plugins
        @input_plugins.each { |plugin|
          plugin_status = plugin.get_status
          details[plugin.name] = plugin_status
          estimates << plugin_status['estimate']
        }
        @last_results = details


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

      def get_status
        status = {
          "time" => Time.now,
          "name" => @name,
          "current" => @current,
          "current_estimate" => @current_estimate,
          "last_changed" => @last_change_ts,
          "results" => @last_results,
        }
        return status
      end

      def run
        now = Time.now

        before = get_current_resource
        @current_estimate = get_combined_estimate

        if @current_estimate != before
          scale
        end
        after = get_current_resource

        if before != after
          puts "CHANGE: #{before} => #{after}"
          @last_change_ts = Time.now
        end
        @current = after
        log_status(now)

        handle_stats(now, @current_estimate, before, after)
      end

      def log_status(now)
        details = ""
        @last_results.each { |name, result|
          details += "#{name}: #{result["value"]}, #{result["estimate"]}; "
        }
        puts "#{now} [combined: #{@current_estimate}]  #{details}"
      end

      # Built-in stats callback: librato
      def librato_send(stats)
        if @librato_api_key.nil? || @librato_api_key.empty? || @librato_email.nil? || @librato_email.empty?
          puts "No librato api key and email"
          return
        end
        begin
          Librato::Metrics.authenticate(@librato_email, @librato_api_key)

          metrics = {}
          stats[:plugins].keys.sort.each { |name|
            result = stats[:plugins][name]
            metrics["dynosaur.#{@heroku_app_name}.#{name}.value"] = result["value"]
            metrics["dynosaur.#{@heroku_app_name}.#{name}.estimate"] = result["estimate"]
          }
          metrics["dynosaur.#{@heroku_app_name}.combined.actual"] = stats[:after]
          metrics["dynosaur.#{@heroku_app_name}.combined.estimate"] = stats[:estimate]

          Librato::Metrics.submit(metrics)
        rescue Exception => e
          puts "Error sending librato metrics"
          puts e.message
        end
      end


      def handle_stats(now, combined_estimate, before, after)
        stats = {
          :plugins => @last_results, # try to minimize race conditions in the iteration
          :ts => now,
          :estimate => combined_estimate,
          :before => before,
          :after => after
        }
        if !@stats_callback.nil?
          @stats_callback.call(stats)
        end
      end

      #
      # We don't have access to #blank? and it would be dumb to include activesupport
      # for only one method
      #
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
