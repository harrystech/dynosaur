
require 'heroku-api'
require 'pry'

class HerokuManager
    HEROKU_POLL_INTERVAL = 60
    attr_reader :retrievals
    def initialize(api_key, app_name, dry_run=false, interval=HEROKU_POLL_INTERVAL)
        @api_key = api_key
        @app_name = app_name
        @dry_run = dry_run
        @interval = interval
        @current_dynos = 0
        @last_retrieved_ts = nil
        @retrievals = 0
        @heroku = Heroku::API.new(:api_key => @api_key)
    end

    def get_current_dynos
        now = Time.now
        if @last_retrieved_ts.nil? || now > (@last_retrieved_ts + @interval)
            begin
                @retrievals += 1
                @current_dynos = self.retrieve
                @last_retrieved_ts = now
            rescue Exception => e
                puts "Error in heroku retrieve : #{e.inspect}"
                @current_dynos = -1
            end
        end
        return @current_dynos
    end

    def retrieve
        # If we're dry-running, we'll pretend
        if @dry_run
            puts "DRY RUN: using last set dynos instead of hitting the API (#{@current_dynos})"
            return @current_dynos
        end
        @state = @heroku.get_app(@app_name).body
        return @state["dynos"]
    end

    def set(dynos)
        puts "Setting current dynos to #{dynos}"
        if not @dry_run
            #@heroku.post_ps_scale(@app_name, 'web', dynos)
        end
        @current_dynos = dynos
    end

    def ensure(dynos)
        @last_retrieved_ts = nil
        current = get_current_dynos
        if current != dynos
            set(dynos)
        else
            puts "Current dynos already at #{dynos}"
        end
    end

end



