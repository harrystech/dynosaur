require 'spec_helper'

describe Dynosaur::Stats::Librato do
  let(:config) {
    {
      "api_key" => SecureRandom.uuid,
      "api_email" => "your_friend@harrys.com",
    }
  }

  let(:app_name) { Faker::Lorem.word }
  before do
    @handler = Dynosaur::Stats::Librato.new(config)
  end
  it 'should send stats' do

    plugins = [Dynosaur::Inputs::RandomPlugin.new({"name" => 'rando'}),
               Dynosaur::Inputs::SinePlugin.new({"name" => 'rando2'})]

    combined_estimate = 3
    combined_actual = 4

    expect(Librato::Metrics).to receive(:submit).with(hash_including({
      "dynosaur.#{app_name}.rando.value" => plugins[0].get_value,
      "dynosaur.#{app_name}.combined.actual" => combined_actual
    }))
    @handler.report(app_name, plugins, combined_estimate, combined_actual)
  end

end