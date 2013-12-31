require 'dynosaur/scaler_plugin'
require 'dynosaur/heroku_manager'
require 'dynosaur/version'

require 'pp'
require 'json'
require 'librato/metrics'

module Dynosaur
    class << self
        DEFAULT_MIN_WEB_DYNOS = 2
        DEFAULT_MAX_WEB_DYNOS = 100
        DEFAULT_SCALER_INTERVAL = 5      # seconds between wakeups
        DEFAULT_DOWNSCALE_BLACKOUT = 300 # seconds to wait after change before dropping

        attr_reader :min_web_dynos, :max_web_dynos, :heroku_app_name, :heroku_api_key, :plugins, :current_estimate, :current, :interval, :dry_run
        attr_accessor :stats_callback

        def initialize(config)
            puts "Dynosaur version #{Dynosaur::VERSION} initializing"

            # Config defaults
            @min_web_dynos = DEFAULT_MIN_WEB_DYNOS
            @max_web_dynos = DEFAULT_MAX_WEB_DYNOS
            @dry_run = false
            @stats = false
            @interval = DEFAULT_SCALER_INTERVAL
            @blackout = DEFAULT_DOWNSCALE_BLACKOUT
            @heroku_api_key = nil
            @heroku_app_name = nil
            @librato_api_key = nil
            @librato_email = nil

            load_plugins
            unless config.nil?
              global_config(config["scaler"])
              config_plugins(config["plugins"])
            end

            # State variables
            @stopped = false
            @current_estimate = 0
            @current = 0
            @desired_state = @min_web_dynos
            @last_change_ts = nil
            @last_results = {}
            @server = nil
            @stats_callback = self.method(:librato_send) # default built-in stats callback

        end


        # Start the autoscaler engine loop
        def start_autoscaler
            @stopped = false
            @heroku_manager = HerokuManager.new(@heroku_api_key, @heroku_app_name, @dry_run)
            while true do
                if @stopped
                    break
                end
                now = Time.now

                before = @heroku_manager.get_current_dynos
                @current_estimate = get_combined_estimate
                @desired_state = get_desired_state(before, @current_estimate, now)

                if @desired_state != before
                    @heroku_manager.ensure(@desired_state)
                end
                after = @heroku_manager.get_current_dynos

                if before != after
                    puts "CHANGE: #{before} => #{after}"
                    @last_change_ts = Time.now
                end
                @current = after
                details = ""
                @last_results.each { |name, result|
                    details += "#{name}: #{result["value"]}, #{result["estimate"]}; "
                }
                puts "#{now} current: #{@current_estimate}; #{before}=>#{after}] - #{details}"

                sleep @interval
                handle_stats(now, @current_estimate, @desired_state, before, after)
            end
        end

        def stop_autoscaler
            @stopped = true
        end

        def stop
            stop_autoscaler
        end

        # start the autoscaler in a new thread
        def start_in_thread
            thread = Thread.new {
                start_autoscaler
            }
            return thread
        end

        # Get status hash (used in dynosaur-rails)
        def get_status
            status = {
                "time" => Time.now,
                "current" => @current,
                "current_estimate" => @current_estimate,
                "last_changed" => @last_change_ts,
                "results" => @last_results,
            }
            return status
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

        def get_combined_estimate
            estimates = []
            details = {}
            now = Time.now
            # Get the estimated dynos from all configured plugins
            @plugins.each { |plugin|
                value = plugin.get_value
                estimate = plugin.estimated_dynos  # minor race condition, but only matters for logging
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

            combined_estimate = [@max_web_dynos, combined_estimate].min
            combined_estimate = [@min_web_dynos, combined_estimate].max

            return combined_estimate
        end

        # Give the current desired state, taking into account hysteresis i.e. blackout period
        # where we do not drop down for x seconds after any change up OR down.
        def get_desired_state(current, estimate, now)
            if estimate >= current
                return estimate  # always scale up quickly
            end

            if @last_change_ts.nil? || @last_change_ts + @blackout < now
                return current - 1
            end

            puts "In blackout, not dropping again until #{@last_change_ts + @blackout}"
            return current
        end

        private
        def load_plugins
            # Load plugins (see glob on next line)
            load_path = File.join(File.dirname(__FILE__), "dynosaur", "*_plugin.rb")
            puts "Loading plugins from #{load_path}"
            Gem.find_files(load_path).each { |path|
                if path.split("/")[-1] == "scaler_plugin.rb"
                    next
                end
                puts "Loading #{path}"
                load path
            }
        end

        def global_config(scaler_config)
            # Get the values from the global config
            if scaler_config.nil?
                raise "Please include a 'scaler' block in the config"
            end
            @min_web_dynos = scaler_config.fetch("min_web_dynos", @min_web_dynos)
            @max_web_dynos = scaler_config.fetch("max_web_dynos", @max_web_dynos)
            @dry_run = scaler_config.fetch("dry_run", @dry_run)
            @stats = scaler_config.fetch("stats", @stats)
            @interval = scaler_config.fetch("interval", @interval)
            @blackout = scaler_config.fetch("blackout", @blackout)
            @librato_api_key = scaler_config.fetch("librato_api_key", @librato_api_key)
            @librato_email = scaler_config.fetch("librato_email", @librato_email)

            @heroku_api_key = scaler_config.fetch("heroku_api_key", @heroku_api_key)
            @heroku_app_name = scaler_config.fetch("heroku_app_name", @heroku_app_name)

            if @heroku_api_key.nil? || @heroku_app_name.nil?
                raise "You must specify your heroku API key and app name in the scaler section of config"
            end

        end

        # Take the plugin config and return a bunch of plugin instances
        # No magic, we just compare config['type'] to the plugin class name
        def config_plugins(plugin_config)
            @plugins = []
            plugin_config.each { |config|
                @plugins << config_one_plugin(config)
            }
            return @plugins
        end

        def config_one_plugin(config)
            subclasses = ScalerPlugin.subclasses
            plugin = nil
            subclasses.each { |klass|
                if klass.name == config["type"]
                    puts "Instantiating #{klass.name} for config '#{config["name"]}'"
                    plugin = klass.new(config)
                    break
                end
            }
            # Error if plugin type was not found
            if plugin.nil?
                raise "Couldn't find plugin type #{config["type"]}"
            end
            return plugin
        end

        def handle_stats(now, combined_estimate, desired_state, before, after)
            results = @last_results  # try to minimize race conditions in the iteration
            stats = {
              :plugins => results,
              :ts => now,
              :estimate => combined_estimate,
              :desired => desired_state,
              :before => before,
              :after => after
            }
          if !@stats_callback.nil?
            @stats_callback.call(stats)
          end
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
            rescue
              puts "Error sending librato metrics"
            end
        end


    end
end
