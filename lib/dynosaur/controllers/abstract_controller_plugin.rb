
module Dynosaur
  module Controllers
    class AbstractControllerPlugin < Dynosaur::BasePlugin

      attr_reader :input_plugins, :current_estimate, :current, :dry_run

      def initialize(config)
        super(config)

        @value = nil
        # State variables
        @stopped = false
        @current_estimate = 0
        @current = 0
        @dry_run = config.fetch("dry_run", false)

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
          return klass.new(input_plugin_config)
        rescue NameError => e
          raise "Could not load #{input_plugin_config['type']}, #{e.message}"
        end
      end

      def heroku_manager
        @heroku_manager ||= HerokuManager.new(@heroku_api_key, @heroku_app_name, @dry_run)
      end


      def get_combined_estimate
        estimates = []
        details = {}
        now = Time.now
        # Get the estimated dynos from all configured plugins
        @input_plugins.each { |plugin|
          value = plugin.get_value
          estimate = plugin.estimated_resources  # minor race condition, but only matters for logging
          health = "OK"
          if now - plugin.last_retrieved_ts > plugin.interval
            health = "STALE"
          end
          details[plugin.name] = {
            "estimate" => estimate,
            "value" => value,
            "unit" => plugin.unit,
            "last_retrieved" => plugin.last_retrieved_ts,
            "health" => health

          }
          estimates << estimate
        }
        @last_results = details


        # Combine the estimates and mo
        combined_estimate = estimates.max

        combined_estimate = [@max_resource, combined_estimate].min
        combined_estimate = [@min_resource, combined_estimate].max

        return combined_estimate
      end

      # Modify config at runtime
      def set_config(config)
        puts "Dynosaur reconfig:"
        pp  config

        if config.has_key?("scaler")
          puts "Modifying scaler config"
          global_config(config["scaler"])
        end
        if config.has_key?("plugins")
          config["plugins"].each { |plugin_config|
            found = nil
            @plugins.each { |plugin|
              if plugin.name == plugin_config["name"]
                puts "Replacing config for #{plugin.name}"
                @plugins.delete(plugin)
              end
            }
            if found.nil?
              puts "Configuring new plugin"
            end
            @plugins << config_one_plugin(plugin_config)
          }
        end
      end

      def scale
        raise NotImplementedError.new("You must define scale in your controller")
      end

      def get_current_resource
        raise NotImplementedError.new("You must define get_current_resource in your controller")
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
        details = ""
        @last_results.each { |name, result|
          details += "#{name}: #{result["value"]}, #{result["estimate"]}; "
        }
        puts "#{now} [combined: #{@current_estimate}]  #{details}"

        handle_stats(now, @current_estimate, before, after)
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
        results = @last_results  # try to minimize race conditions in the iteration
        stats = {
          :plugins => results,
          :ts => now,
          :estimate => combined_estimate,
          :before => before,
          :after => after
        }
        if !@stats_callback.nil?
          @stats_callback.call(stats)
        end
      end


    end # AbstractControllerPlugin
  end # Controllers
end # Dynosaur
