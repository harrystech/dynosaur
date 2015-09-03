require 'librato/metrics'

module Dynosaur::Stats
  class Librato

    def initialize(config)
      @api_email = config["api_email"]
      @api_key = config["api_key"]

      if @api_email.blank? || @api_key.blank?
        raise ArgumentError.new "Must supply email and api key for librato"
      end
    end

    # Log stats for this controller:
    # name = name of heroku app typically
    # plugins = list of the plugins
    # combined_estimate: what the estimated resource level is after all plugins
    #                    are combined
    # combined_actual: what we actually set the resource level at taking into
    #                  account min/max, hysteresis etc.
    def report(name, plugins, combined_estimate, combined_actual)
        ::Librato::Metrics.authenticate(@librato_email, @librato_api_key)

        metrics = {}
        plugins.each do |plugin|
          metrics["dynosaur.#{name}.#{plugin.name}.value"] = plugin.get_value
          metrics["dynosaur.#{name}.#{plugin.name}.estimate"] = plugin.estimated_resources
        end
        metrics["dynosaur.#{name}.combined.actual"] = combined_actual
        metrics["dynosaur.#{name}.combined.estimate"] = combined_estimate

        ::Librato::Metrics.submit(metrics)
    rescue Exception => e
      puts "Error sending librato metrics"
      puts e.message
    end
  end

end
