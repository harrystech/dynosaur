
require 'platform-api'

module Dynosaur
  class HerokuManager
    HEROKU_POLL_INTERVAL = 60
    attr_reader :retrievals

    def initialize(api_key, app_name, dry_run=false, interval=HEROKU_POLL_INTERVAL)
      @api_key = api_key
      @app_name = app_name
      @dry_run = dry_run
      @interval = interval
      @current_value = 0
      @last_retrieved_ts = nil
      @retrievals = 0

      # TODO: We should migrate entirely to the platform API
      @heroku_platform_api = PlatformAPI.connect_oauth(@api_key)
    end

    def get_current_value
      now = Time.now
      if @last_retrieved_ts.nil? || now > (@last_retrieved_ts + @interval)
        begin
          @retrievals += 1
          # If we're dry-running, we'll pretend
          @current_value = self.retrieve
          @last_retrieved_ts = now
        rescue SystemExit, Interrupt # purposeful quit, ctrl-c, kill signal etc
          raise
        rescue StandardError => e
          puts "Error in heroku retrieve : #{e.inspect}"
          Dynosaur::ErrorHandler.handle(e)
          @current_value = -1
          raise
        end
      end
      return @current_value
    end

    def ensure_value(value)
      @last_retrieved_ts = nil
      current = get_current_value
      if @dry_run
        puts "DRY RUN: would have changed #{current} to #{value}"
        return
      end
      if current != value
        set(value)
      else
        puts "Current value already at #{value}"
      end
    end

  end

end
