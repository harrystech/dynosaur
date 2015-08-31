require 'spec_helper'

require 'dynosaur/error_handler/console'

describe Dynosaur::ErrorHandler::Console do
  it 'should handle exception' do
    handler = Dynosaur::ErrorHandler::Console.new({})

    begin
      raise StandardError.new "Dummy Error"
    rescue StandardError => e
      handler.handle(e)
    end
  end
end
