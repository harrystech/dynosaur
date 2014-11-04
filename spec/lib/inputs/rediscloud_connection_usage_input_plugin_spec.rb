require 'spec_helper'
require 'dynosaur/inputs/rediscloud_connection_usage_input_plugin'

describe Dynosaur::Inputs::RediscloudConnectionUsageInputPlugin do
  let(:plugin) {
    Dynosaur::Inputs::RediscloudConnectionUsageInputPlugin.new({
      "name" => 'test',
      "component_id" => 42,
    })
  }

  describe '#value_to_resources' do
    context 'when using 240 connections (more than 90%)' do
      it "should return rediscloud:250" do
        plugin.value_to_resources(240)['name'].should eq("rediscloud:500")
      end
    end

    context 'when using 400 connections' do
      it "should return rediscloud:500" do
        plugin.value_to_resources(400)['name'].should eq("rediscloud:500")
      end
    end

    context 'when using 30 connections' do
      it "should return rediscloud:100" do
        plugin.value_to_resources(30)['name'].should eq("rediscloud:100")
      end
    end

    context 'when using 1000 connections' do
      it "should return rediscloud:2500" do
        plugin.value_to_resources(1000)['name'].should eq("rediscloud:2500")
      end
    end

    context 'when using 10000 connections' do
      it "should return rediscloud:2500" do
        plugin.value_to_resources(10000)['name'].should eq("rediscloud:2500")
      end
    end
  end

  describe "#retrieve" do
    it "calls the new relic API" do
      expect_any_instance_of(Faraday::Connection).to receive(:post).once.and_call_original
      stub_redis_connection_usage(10.0)
      expect(plugin.retrieve).to be_a Float
    end
  end

  describe '#estimated_resources' do
    it "returns the correct estimate" do
      stub_redis_connection_usage(10)
      expect(plugin.estimated_resources).to be_a AddonPlan
    end
  end

end
