require 'spec_helper'
require 'dynosaur/error_handler/ses'

describe Dynosaur::ErrorHandler::Ses do

  let(:config) do
    {
      to: "aoneill@harrys.com",
      from: "dynosaur@harrys.com",
      aws_access_key_id: "JKHDKJHEJKH",
      aws_secret_access_key: "KJHDKJEHDKJEHDH"
    }
  end

  it 'should handle' do
    handler = Dynosaur::ErrorHandler::Ses.new(config)

    ses = handler.instance_variable_get("@ses")
    expect(ses).to receive(:send_email).with(hash_including({to: config[:to],
                                             from: config[:from],
                                             subject: "Dynosaur Error"}))
    begin
      raise StandardError.new "Dummy Error"
    rescue StandardError => e
      handler.handle(e)
    end

  end

end
