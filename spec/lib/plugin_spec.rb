require 'spec_helper'

require 'analytics_dyno_scaler'
require 'pry'

describe "Plugins" do
    it "should retrieve and cache value properly" do
        config = get_config_with_test_plugin
        config["plugins"][0]["interval"] = 30
        AnalyticsDynoScaler.initialize(config)
        rand = AnalyticsDynoScaler.plugins[0]
        rand.interval.should eql 30

        # Retrieve the get_value again before cache times out
        ret0 = rand.retrievals
        val1 = rand.get_value()
        rand.retrievals.should eql 1

        val2 = rand.get_value()

        val2.should eql val1
        rand.retrievals.should eql 1
    end

    it "should retrieve and re-retrieve value properly" do
        config = get_config_with_test_plugin
        config["plugins"][0]["interval"] = 0.1
        AnalyticsDynoScaler.initialize(config)
        rand = AnalyticsDynoScaler.plugins[0]
        rand.interval.should eql 0.1

        # retrieve then wait for cache to expire and re-retrieve
        ret0 = rand.retrievals
        val1 = rand.get_value()
        rand.retrievals.should eql 1

        sleep 0.11
        val2 = rand.get_value()

        rand.retrievals.should eql 2
    end

    it "should calculate the dynos properly" do
        config = get_config_with_test_plugin
        AnalyticsDynoScaler.initialize(config)
        rand = AnalyticsDynoScaler.plugins[0]

        val = rand.get_value()
        dynos = rand.estimated_dynos
        rand.retrievals.should eql 1  # make sure the value hasn't changed
        dynos.should eql val / 2

    end
end
