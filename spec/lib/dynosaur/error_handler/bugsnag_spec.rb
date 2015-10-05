require 'spec_helper'

require 'dynosaur/error_handler/bugsnag'

describe Dynosaur::ErrorHandler::Bugsnag do
  it 'should handle exception' do
    handler = Dynosaur::ErrorHandler::Bugsnag.new({api_key: SecureRandom.uuid})

    begin
      raise StandardError.new "Dummy Error"
    rescue StandardError => e
      expect(Bugsnag).to receive(:notify).with(e)
      handler.handle(e)
    end
  end
end
