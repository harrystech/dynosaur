require 'analytics_dyno_scaler/scaler_plugin'
require 'analytics_dyno_scaler/heroku_manager'

module AnalyticsDynoScaler
    class << self
        DEFAULT_MIN_WEB_DYNOS = 2
        DEFAULT_MAX_WEB_DYNOS = 100
        DEFAULT_SCALER_INTERVAL = 5   # seconds between wakeups

        attr_reader :min_web_dynos, :max_web_dynos, :heroku_app_name, :heroku_api_key, :plugins, :current_estimate, :current

        def initialize(config)
            puts "Running initialize"
            load_plugins
            global_config(config["scaler"])
            config_plugins(config["plugins"])
            @stopped = false
            @current_estimate = 0
            @current = 0
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

                previous = @heroku_manager.get_current_dynos
                @current_estimate, details = get_combined_estimate

                @heroku_manager.ensure(@current_estimate)
                @current = @heroku_manager.get_current_dynos

                if previous != @current
                    puts "CHANGE: #{previous} => #{@current}"
                end
                puts "#{now} [#{@current} / #{@current_estimate}] - #{details}"
                sleep @interval
            end
        end

        def stop_autoscaler
            @stopped = true
        end

        # start the autoscaler in a new thread
        def start_in_thread
            thread = Thread.new {
                start_autoscaler
            }
            return thread
        end

        def get_combined_estimate
            estimates = []
            status = ""
            # Get the estimated dynos from all configured plugins
            @plugins.each { |plugin|
                value = plugin.get_value
                estimate = plugin.estimated_dynos  # minor race condition, but only matters for logging
                status += "[#{plugin.name}] #{value} #{plugin.unit}, #{estimate} dynos;  "
                estimates << estimate
            }

            # Combine the estimates and mo
            combined_estimate = estimates.max

            combined_estimate = [@max_web_dynos, combined_estimate].min
            combined_estimate = [@min_web_dynos, combined_estimate].max

            return combined_estimate, status
        end

        private
        def load_plugins
            # Load plugins (see glob on next line)
            Gem.find_files('analytics_dyno_scaler/*_plugin.rb').each { |path|
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
            @min_web_dynos = scaler_config.has_key?("min_web_dynos") ? scaler_config["min_web_dynos"] : DEFAULT_MIN_WEB_DYNOS
            @max_web_dynos = scaler_config.has_key?("max_web_dynos") ? scaler_config["max_web_dynos"] : DEFAULT_MAX_WEB_DYNOS
            @dry_run = scaler_config.has_key?("dry_run") ? scaler_config["dry_run"] : false
            @interval = scaler_config.has_key?("interval") ? scaler_config["interval"] : DEFAULT_SCALER_INTERVAL

            if scaler_config["heroku_api_key"].nil? || scaler_config["heroku_app_name"].nil?
                raise "You must specify your heroku API key and app name in the scaler section of config"
            end

            @heroku_api_key = scaler_config["heroku_api_key"]
            @heroku_app_name = scaler_config["heroku_app_name"]
        end

        # Take the plugin config and return a bunch of plugin instances
        # No magic, we just compare config['type'] to the plugin class name
        def config_plugins(plugin_config)
            subclasses = ScalerPlugin.subclasses

            @plugins = []
            plugin_config.each { |config|
                plugin = nil
                puts "Configuring plugin #{config["name"]}"
                subclasses.each { |klass|
                    if klass.name == config["type"]
                        puts "Instantiating #{klass.name} for config #{config["name"]}"
                        plugin = klass.new(config)
                        break
                    end
                }
                # Error if plugin type was not found
                if plugin.nil?
                    raise "Couldn't find plugin type #{config["type"]}"
                end
                @plugins << plugin
            }
            return @plugins
        end


    end
end
