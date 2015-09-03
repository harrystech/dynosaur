module Dynosaur::Stats
  class Console

    def initialize(config)
    end

    # Log stats for this controller:
    # name = name of heroku app typically
    # plugins = list of the plugins
    # combined_estimate: what the estimated resource level is after all plugins
    #                    are combined
    # combined_actual: what we actually set the resource level at taking into
    #                  account min/max, hysteresis etc.
    def report(name, plugins, combined_estimate, combined_actual)
        plugins.each do |plugin|
          puts "dynosaur.#{name}.#{plugin.name}.value: #{plugin.get_value}"
          puts "dynosaur.#{name}.#{plugin.name}.estimate: #{plugin.estimated_resources}"
        end
        puts "dynosaur.#{name}.combined.actual: #{combined_actual}"
        puts "dynosaur.#{name}.combined.estimate: #{combined_estimate}"
    end
  end

end
