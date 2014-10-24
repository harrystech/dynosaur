
module Dynosaur
  module Controllers
    class DynosControllerPlugin < AbstractControllerPlugin
      DEFAULT_MIN_WEB_DYNOS = 2
      DEFAULT_MAX_WEB_DYNOS = 100

      attr_reader :min_web_dynos, :max_web_dynos

      def initialize(config)
        super(config)
        @min_web_dynos = config.fetch('min_web_dynos', DEFAULT_MIN_WEB_DYNOS)
        @max_web_dynos = config.fetch('max_web_dynos', DEFAULT_MAX_WEB_DYNOS)
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

      def scale
        @heroku_manager.ensure_number_of_dynos(@current_estimate)
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

    end # DynosControllerPlugin
  end # Controllers
end # Dynosaur
