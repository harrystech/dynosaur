require 'spec_helper'
require 'dynosaur/inputs/papertrail_input_plugin'

describe Dynosaur::Inputs::PapertrailInputPlugin do
  let(:plugin) {
    Dynosaur::Inputs::PapertrailInputPlugin.new({
      "name" => 'test',
    })
  }

  describe '#value_to_resources' do
    context 'when using 49 MB (more than 90%)' do
      it "should return papertrail:ludvig" do
        plugin.value_to_resources(51380224)['name'].should eq("papertrail:ludvig")
      end
    end

    context 'when using 150 MB' do
      it "should return papertrail:forsta" do
        plugin.value_to_resources(157286400)['name'].should eq("papertrail:forsta")
      end
    end

    context 'when using 89 MB (less than 90%)' do
      it "should return papertrail:ludvig" do
        plugin.value_to_resources(93323264)['name'].should eq("papertrail:ludvig")
      end
    end
  end

  describe "#retrieve" do
    it "calls the new relic API" do
      expect_any_instance_of(Faraday::Connection).to receive(:get).once.and_call_original
      stub_papertrail_api(1024 * 1024 + 1024)
      expect(plugin.retrieve).to be_a Numeric
    end
  end

  describe '#estimated_resources' do
    it "returns the correct estimate" do
      stub_papertrail_api(1024 * 1024 + 1024)
      expect(plugin.estimated_resources).to be_a AddonPlan
    end
  end

  describe 'daily_reset' do
    before do
      plugin.instance_variable_set(:@interval, 30)
    end
    after do
      Timecop.return
    end
    it 'resets the historical data after 00:00 UTC' do
      now = Time.parse '2014-10-29 23:59:10 -0000'
      stub_papertrail_api(1024 * 1024 + 1024)
      Timecop.freeze(now) do
        plugin.estimated_resources
      end
      # 31s later
      Timecop.freeze(now + 31) do
        plugin.estimated_resources
      end
      plugin.recent.size.should eq(2)

      # 31s later
      Timecop.freeze(now + 62) do
        plugin.estimated_resources
      end
      plugin.recent.size.should eq(1)
    end

    it 'only resets once' do
      now = Time.parse '2014-10-29 23:59:55 -0000'
      stub_papertrail_api(1024 * 1024 + 1024)
      expect(plugin.recent).to receive(:clear).once
      Timecop.freeze(now) do
        plugin.estimated_resources
      end

      Timecop.freeze(now + 11) do
        plugin.estimated_resources
      end

      Timecop.freeze(now + 21) do
        plugin.estimated_resources
      end

      Timecop.freeze(now + 31) do
        plugin.estimated_resources
      end
    end
  end

end
