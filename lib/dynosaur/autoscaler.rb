
require 'dynosaur/heroku_manager'
require 'dynosaur/heroku_dyno_manager'
require 'dynosaur/heroku_addon_manager'
require 'dynosaur/version'
require 'dynosaur/error_handler'
require 'dynosaur/ring_buffer'
require 'dynosaur/addon_plan'
require 'dynosaur/base_plugin'
require 'dynosaur/controllers/abstract_controller_plugin'
require 'dynosaur/inputs/abstract_input_plugin'
require 'dynosaur/stats'

require 'pp'

module Dynosaur

  class Autoscaler
    DEFAULT_SCALER_INTERVAL = 5      # seconds between wakeups

    attr_accessor :heroku_app_name, :controller_plugins, :debug, :dry_run

    def initialize(config)
      STDOUT.sync = true
      puts "Dynosaur version #{Dynosaur::VERSION} initializing"
      if config.nil?
        raise ArgumentError.new "Must supply config hash"
      end

      # Config defaults
      @dry_run = false
      @stats = false
      @debug = false
      @interval = DEFAULT_SCALER_INTERVAL
      @heroku_api_key = nil
      @heroku_app_name = nil
      @controller_plugins = []

      # Setup error handler plugins
      ErrorHandler.initialize(config["error_handlers"])

      global_config(config["scaler"])

      # Set up Statistics handler plugins
      @stats_handlers = config_stats_handlers config["stats_plugins"]

      @success_handlers = config_success_handlers config["success_handlers"]

      # Load all controllers

      config_controller_plugins(config["controller_plugins"])
    end

    # Start the autoscaler engine loop in a begin/rescue block
    def start
      @heroku_manager = nil
      while true do
        begin
          self.run_loop
        rescue SystemExit, Interrupt # purposeful quit, ctrl-c, kill signal etc
          raise
        rescue StandardError => e  # any other error
          ErrorHandler.handle(e)
        end
        sleep @interval
      end
    end

    # Perform one run of the main autoscaler
    def run_loop
      # Run all plugins
      @controller_plugins.each do |controller_plugin|
        controller_plugin.run
        log_stats(controller_plugin)
      end
      trigger_success_handlers
    end

    def trigger_success_handlers
      @success_handlers.each do |handler|
        handler.handle
      end
    end

    def global_config(scaler_config)
      # Get the values from the global config
      if scaler_config.nil?
        raise StandardError.new "Please include a 'scaler' block in the config"
      end
      @dry_run = scaler_config.fetch("dry_run", @dry_run)
      # @stats = scaler_config.fetch("stats", @stats)
      @interval = scaler_config.fetch("interval", @interval)
      @librato_api_key = scaler_config.fetch("librato_api_key", @librato_api_key)
      @librato_email = scaler_config.fetch("librato_email", @librato_email)

      @heroku_api_key = scaler_config.fetch("heroku_api_key", @heroku_api_key)
      @heroku_app_name = scaler_config.fetch("heroku_app_name", @heroku_app_name)

      if @heroku_api_key.nil? || @heroku_app_name.nil?
        raise StandardError.new "You must specify your heroku API key and app name in the scaler section of config"
      end

    end

    def log_stats(controller)
      @stats_handlers.each do |handler|
        handler.report(@heroku_app_name, controller.name, controller.input_plugins, controller.current_estimate, controller.current)
      end
    end

    # Take the plugin config and return a bunch of plugin instances
    # No magic, we just compare config['type'] to the plugin class name
    def config_controller_plugins(controller_plugins_config)
      controller_plugins_config.each { |config|
        @controller_plugins << config_one_plugin(config)
      }
      return @controller_plugins
    end

    def config_stats_handlers(stats_config)
      return [] if stats_config.nil?
      handlers = []
      stats_config.each do |config|
        type = config["type"]
        clazz = type.constantize
        handler = clazz.new(config)
        handlers << handler
      end
      handlers
    end

    def config_success_handlers(success_config)
      return [] if success_config.nil?
      handlers = []
      success_config.each do |config|
        type = config["type"]
        clazz = type.constantize
        handler = clazz.new(config)
        handlers << handler
      end
      handlers
    end


    def config_one_plugin(config)
      subclasses = Dynosaur::Controllers::AbstractControllerPlugin.subclasses
      plugin = nil
      subclasses.each { |klass|
        if klass.name == config["type"]
          puts "Instantiating #{klass.name} for config '#{config["name"]}'"
          if @dry_run
            # Dry run is set globally
            # if it's not set globally, let each controller have its own dry run setting
            config.merge!({"dry_run" => true})
          end
          plugin = klass.new(config.merge({
            "heroku_app_name" => @heroku_app_name,
            "heroku_api_key" => @heroku_api_key,
            "librato_email" => @librato_email,
            "librato_api_key" => @librato_api_key,
          }))
          break
        end
      }
      # Error if plugin type was not found
      if plugin.nil?
        raise StandardError.new "Couldn't find plugin type #{config["type"]}"
      end
      return plugin
    end

  end # << AutoScaler

end # Dynosaur
