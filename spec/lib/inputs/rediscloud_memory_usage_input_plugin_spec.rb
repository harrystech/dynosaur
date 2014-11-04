require 'spec_helper'
require 'dynosaur/inputs/rediscloud_memory_usage_input_plugin'

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
      stub_redis_memory_usage(10.0)
      expect(plugin.retrieve).to be_a Float
    end
  end

  describe '#estimated_resources' do
    it "returns the correct estimate" do
      stub_redis_memory_usage(10)
      expect(plugin.estimated_resources).to be_a AddonPlan
    end
  end

end
