require 'spec_helper'
require 'dynosaur/inputs/rediscloud_memory_usage_input_plugin'

def stub_new_relic_api
  fake_response = {
    "metric_data"=>{
      "from"=>"2014-10-28T14:06:43+00:00",
      "to"=>"2014-10-28T14:36:43+00:00",
      "metrics"=>[{
        "name"=>"Component/redis/Used memory[megabytes]",
        "timeslices"=>[{
          "from"=>"2014-10-28T14:06:00+00:00",
          "to"=>"2014-10-28T14:35:59+00:00",
          "values"=>{"average_value"=>54.9}
        }]
      }]
    }
  }
  stubs = Faraday::Adapter::Test::Stubs.new
  test_connection = Faraday.new do |builder|
    builder.adapter :test, stubs do |stub|
      stub.post('/v2/components/42/metrics/data.json') { |env| [ 200, {}, fake_response.to_json ]}
    end
  end
  allow_any_instance_of(Dynosaur::Inputs::RediscloudMemoryUsageInputPlugin).to receive(:faraday_connection).and_return(test_connection)
end

describe Dynosaur::Inputs::RediscloudMemoryUsageInputPlugin do
  let(:plugin) {
    Dynosaur::Inputs::RediscloudMemoryUsageInputPlugin.new({
      "name" => 'test',
      "component_id" => 42,
    })
  }

  describe '#value_to_resources' do
    context 'when using 95 MB (more than 90%)' do
      it "should return rediscloud:250" do
        plugin.value_to_resources(95)['name'].should eq("rediscloud:250")
      end
    end

    context 'when using 200 MB' do
      it "should return rediscloud:250" do
        plugin.value_to_resources(200)['name'].should eq("rediscloud:250")
      end
    end

    context 'when using 89 MB (less than 90%)' do
      it "should return rediscloud:100" do
        plugin.value_to_resources(89)['name'].should eq("rediscloud:100")
      end
    end
  end

  describe "#retrieve" do
    it "calls the new relic API" do
      expect_any_instance_of(Faraday::Connection).to receive(:post).once.and_call_original
      stub_new_relic_api
      expect(plugin.retrieve).to be_a Float
    end
  end

  describe '#estimated_resources' do
    it "returns the correct estimate" do
      stub_new_relic_api
      expect(plugin.estimated_resources).to be_a AddonPlan
    end
  end

end
