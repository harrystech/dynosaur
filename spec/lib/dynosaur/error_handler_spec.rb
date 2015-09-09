
require 'spec_helper'

require 'dynosaur/error_handler'

describe Dynosaur::ErrorHandler do
  let(:config) do
    [{
      type: "Dynosaur::ErrorHandler::Ses",
      to: "aoneill@harrys.com",
      from: "dynosaur@harrys.com",
      aws_access_key_id: "JKHDKJHEJKH",
      aws_secret_access_key: "KJHDKJEHDKJEHDH"
    },
    {
      type: "Dynosaur::ErrorHandler::Console"
    }]
  end

  it 'should handle exception' do
    Dynosaur::ErrorHandler.initialize(config)

    ses_handler = Dynosaur::ErrorHandler.class_variable_get("@@handlers").first
    ses = ses_handler.instance_variable_get("@ses")
    expect(ses).to receive(:send_email)

    begin
      raise StandardError.new "Dummy Error"
    rescue StandardError => e
      Dynosaur::ErrorHandler.handle(e)
    end
  end
end
