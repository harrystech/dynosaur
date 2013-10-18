
# Test the main scaler logic

require 'spec_helper'
require 'analytics_dyno_scaler'
require 'pry'

describe "scaler" do
    it "should run the loop and modify settings" do

        # The scaler checks every 0.1s
        config = get_config_with_test_plugin

        # The plugin may change every 0.2s
        config["plugins"][0]["interval"] = 0.2
        AnalyticsDynoScaler.initialize(config)

        puts "starting autoscaler"
        thread = AnalyticsDynoScaler.start_in_thread

        3.times { |i|
            sleep 0.11  # sleep for one tick of the scaler
            estimated = AnalyticsDynoScaler.current_estimate
            current = AnalyticsDynoScaler.current
            puts "#{i*0.11}s: Estimated = #{estimated}; Current = #{current}"
            estimated.should eql current
        }
        puts "Stopping autoscaler"
        AnalyticsDynoScaler.stop_autoscaler
        thread.join
    end


    it "should calculate the estimated dynos properly" do
        config = get_config_with_test_plugin(2)

        config["plugins"][0]["interval"] = 0
        config["plugins"][1]["interval"] = 0
        AnalyticsDynoScaler.initialize(config)


        # Check that it picks the max of all plugins
        AnalyticsDynoScaler.plugins[0].stub(:retrieve) { 10 }
        AnalyticsDynoScaler.plugins[1].stub(:retrieve) { 33 }
        combined, details = AnalyticsDynoScaler.get_combined_estimate
        puts "#{combined} - #{details}"
        combined.should eql 17  # 33 / 2 rounded up


        # Check that we are constrained by max_web_dynos
        AnalyticsDynoScaler.plugins[0].stub(:retrieve) { config["scaler"]["max_web_dynos"]*4 }
        AnalyticsDynoScaler.plugins[1].stub(:retrieve) { 27 }
        combined, details = AnalyticsDynoScaler.get_combined_estimate
        puts "#{combined} - #{details}"
        combined.should eql config["scaler"]["max_web_dynos"]


        # Check that we are constrained by min_web_dynos
        AnalyticsDynoScaler.plugins[0].stub(:retrieve) { 0 }
        AnalyticsDynoScaler.plugins[1].stub(:retrieve) { 1 }
        combined, details = AnalyticsDynoScaler.get_combined_estimate
        puts "#{combined} - #{details}"
        combined.should eql config["scaler"]["min_web_dynos"]
    end
end
