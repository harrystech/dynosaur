require 'analytics_dyno_scaler/scaler_plugin'
require 'analytics_dyno_scaler/heroku_manager'

module AnalyticsDynoScaler
    class << self
        DEFAULT_MIN_WEB_DYNOS = 2
        DEFAULT_MAX_WEB_DYNOS = 100
        DEFAULT_SCALER_INTERVAL = 5      # seconds between wakeups
        DEFAULT_DOWNSCALE_BLACKOUT = 300 # seconds to wait after change before dropping

        attr_reader :min_web_dynos, :max_web_dynos, :heroku_app_name, :heroku_api_key, :plugins, :current_estimate, :current

        def initialize(config)
            puts "Running initialize"
            load_plugins
            global_config(config["scaler"])
            config_plugins(config["plugins"])
            @stopped = false
            @current_estimate = 0
            @current = 0
            @desired_state
            @last_change_ts = nil
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
                @current_estimate, details = get_combined_estimate
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
                puts "#{now} [#{before}=>#{after} (#{@current_estimate})] - #{details}"
                sleep @interval
                if @stats
                    output_stats(now, @current_estimate, @desired_state, before, after)
                end
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
            load_path = File.join(File.dirname(__FILE__), "analytics_dyno_scaler", "*_plugin.rb")
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
            @min_web_dynos = scaler_config.has_key?("min_web_dynos") ? scaler_config["min_web_dynos"] : DEFAULT_MIN_WEB_DYNOS
            @max_web_dynos = scaler_config.has_key?("max_web_dynos") ? scaler_config["max_web_dynos"] : DEFAULT_MAX_WEB_DYNOS
            @dry_run = scaler_config.has_key?("dry_run") ? scaler_config["dry_run"] : false
            @stats = scaler_config.has_key?("stats") ? scaler_config["stats"] : false
            @interval = scaler_config.has_key?("interval") ? scaler_config["interval"] : DEFAULT_SCALER_INTERVAL
            @blackout = scaler_config.has_key?("blackout") ? scaler_config["blackout"] : DEFAULT_DOWNSCALE_BLACKOUT

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
                @plugins << plugin
            }
            return @plugins
        end

        def output_stats(now, combined_estimate, desired_state, before, after)
            open('stats.txt', 'a') { |f|
                f.puts "#{now},#{now.to_i},#{combined_estimate},#{desired_state},#{before},#{after}"
            }
        end


    end
end
