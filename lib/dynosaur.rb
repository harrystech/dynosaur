require 'dynosaur/heroku_manager'
require 'dynosaur/version'
require 'dynosaur/error_handler'
require 'dynosaur/ring_buffer'
require 'dynosaur/base_plugin'
require 'dynosaur/controllers/abstract_controller_plugin'
require 'dynosaur/inputs/abstract_input_plugin'

require 'pp'
require 'json'
require 'librato/metrics'

module Dynosaur


  class << self
    DEFAULT_SCALER_INTERVAL = 5      # seconds between wakeups

    attr_accessor :stats_callback, :heroku_app_name, :controller_plugins

    def initialize(config)
      puts "Dynosaur version #{Dynosaur::VERSION} initializing"

      # Config defaults
      @dry_run = false
      @stats = false
      @interval = DEFAULT_SCALER_INTERVAL
      @heroku_api_key = nil
      @heroku_app_name = nil
      @librato_api_key = nil
      @librato_email = nil
      @controller_plugins = []

      ErrorHandler.initialize

      # Load all controllers
      load_controller_plugins
      load_input_plugins
      unless config.nil?
        global_config(config["scaler"])
        config_controller_plugins(config["controller_plugins"])
      end

      # State variables
      @stopped = false
      @last_change_ts = nil
      @last_results = {}
      @server = nil
      # @stats_callback = self.method(:librato_send) # default built-in stats callback
    end

    # Start the autoscaler engine loop in a begin/rescue block
    def start_autoscaler
      @stopped = false
      @heroku_manager = nil
      while true do
        begin
          if @stopped
            break
          end
          self.run_loop
          sleep @interval
        rescue SystemExit, Interrupt # purposeful quit, ctrl-c, kill signal etc
          raise
        rescue Exception => e  # any other error
          ErrorHandler.report(e)
          sleep @interval
        end
      end
    end

    # Perform one run of the main autoscaler
    def run_loop
      # Run all plugins
      @controller_plugins.each do |controller_plugin|
        controller_plugin.run
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


    private
    def load_controller_plugins
      # Load plugins (see glob on next line)
      load_path = File.join(File.dirname(__FILE__), "dynosaur", "controllers", "*_plugin.rb")
      puts "Loading plugins from #{load_path}"
      Gem.find_files(load_path).each { |path|
        if path.split("/")[-1] == "abstract_controller_plugin.rb"
          next
        end
        puts "Loading #{path}"
        load path
      }
    end

    def load_input_plugins
      # Load plugins (see glob on next line)
      load_path = File.join(File.dirname(__FILE__), "dynosaur", "inputs", "*_plugin.rb")
      puts "Loading plugins from #{load_path}"
      Gem.find_files(load_path).each { |path|
        if path.split("/")[-1] == "abstract_input_plugin.rb"
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
      # @min_web_dynos = scaler_config.fetch("min_web_dynos", @min_web_dynos)
      # @max_web_dynos = scaler_config.fetch("max_web_dynos", @max_web_dynos)
      @dry_run = scaler_config.fetch("dry_run", @dry_run)
      # @stats = scaler_config.fetch("stats", @stats)
      @interval = scaler_config.fetch("interval", @interval)
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
    def config_controller_plugins(controller_plugins_config)
      @controller_plugins = []
      controller_plugins_config.each { |config|
        @controller_plugins << config_one_plugin(config)
      }
      return @controller_plugins
    end

    def config_one_plugin(config)
      subclasses = Dynosaur::Controllers::AbstractControllerPlugin.subclasses
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

  end
end
