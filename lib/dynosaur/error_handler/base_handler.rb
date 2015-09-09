

module Dynosaur::ErrorHandler
  class BaseHandler

    def initialize(config)
    end

    def handle(exception)
      raise NotImplementedError.new("You must define handle in your plugin")
    end
  end
end

