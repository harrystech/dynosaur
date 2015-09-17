require 'spec_helper'

describe Dynosaur::Inputs::NewRelicInputPlugin do
  let(:plugin) { Dynosaur::Inputs::NewRelicInputPlugin.new(config) }
  let(:config) { {'name' => 'New Relic Input', 'key' => api_key, 'app_id' => app_id} }
  let(:api_key) { SecureRandom.hex 4 }
  let(:app_id) { SecureRandom.hex 4 }
  let(:api_client) { Dynosaur::NewRelicApiClient.new(nil, nil) }
  let(:response_data) {
    {
      "metric_data" => {
        "from" =>  "2015-09-15T16:25:57+00:00",
        "to" =>  "2015-09-15T16:55:57+00:00",
        "metrics" => [
          {
            "name" =>  "HttpDispatcher",
            "timeslices" => [
              {
                "from" =>  "2015-09-15T16:25:00+00:00",
                "to" =>  "2015-09-15T16:26:00+00:00",
                "values" => { "call_count" => 20 },
              },
              {
                "from" =>  "2015-09-15T16:26:00+00:00",
                "to" =>  "2015-09-15T16:27:00+00:00",
                "values" => { "call_count" => 10 },
              },
            ],
          },
        ],
      },
    }
  }
  let(:test) {
    Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.post('/v2/components/metrics/data.json') { |env| [ 200, {}, response_data.to_json ]}
      end
    end
  }

  it { expect(plugin).to_not be_nil }

  describe '#retrieve' do
    before do
      allow(api_client).to receive(:faraday_connection).and_return(test)
      plugin.instance_variable_set(:@new_relic_api_client, api_client)
    end

    it "fetches the most recent data from NR" do
      expect(plugin.retrieve).to eq(10)
    end
  end
end
