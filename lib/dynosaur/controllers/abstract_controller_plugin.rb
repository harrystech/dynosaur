
module Dynosaur
  module Controllers
    class AbstractControllerPlugin < Dynosaur::BasePlugin

      attr_reader :input_plugins

      def initialize(config)
        super(config)
        load_input_plugins config['input_plugins']
      end

      def load_input_plugins(input_plugins_config)
        @input_plugins = []
        (input_plugins_config || []).each do |input_plugin_config|
          @input_plugins << load_input_plugin(input_plugin_config)
        end
      end

      def load_input_plugin(input_plugin_config)
        # Load the class and instanciate it
        begin
          klass = Kernel.const_get(input_plugin_config['type'])
          return klass.new(input_plugin_config)
        rescue NameError => e
          raise "Could not load #{input_plugin_config['type']}"
        end
      end

    end
  end
end
