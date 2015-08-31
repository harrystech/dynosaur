module Dynosaur::ErrorHandler
  class Console < BaseHandler
    def initialize(config)
      super
    end

    def handle(exception)
        puts "========= ERROR ==========="
        puts exception.message
        puts exception.backtrace.join("\n")
    end
  end
end
