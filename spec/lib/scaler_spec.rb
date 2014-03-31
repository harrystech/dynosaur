
# Test the main scaler logic

require 'spec_helper'
require 'dynosaur'

describe "scaler" do
  it "should run the loop and modify settings" do

    # The scaler checks every 0.1s
    config = get_config_with_test_plugin

    # The plugin may change every 0.2s
    config["plugins"][0]["interval"] = 0.2
    Dynosaur.initialize(config)

    puts "starting autoscaler"
    thread = Dynosaur.start_in_thread

    3.times { |i|
      sleep 0.11  # sleep for one tick of the scaler
      estimated = Dynosaur.current_estimate
      current = Dynosaur.current
      puts "#{i*0.11}s: Estimated = #{estimated}; Current = #{current}"
      (current >= estimated).should be_true
    }
    puts "Stopping autoscaler"
    Dynosaur.stop_autoscaler
    thread.join
  end


  context "given multiple plugin configs" do
    before do
      @config = get_config_with_test_plugin(2)

      @config["plugins"][0]["interval"] = 0.1
      @config["plugins"][1]["interval"] = 0.1
      Dynosaur.initialize(@config)
    end


    it "should pick the maximum estimate" do
      Dynosaur.plugins[0].stub(:retrieve) { 10 }
      Dynosaur.plugins[1].stub(:retrieve) { 33 }
      combined, details = Dynosaur.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql 17  # 33 / 2 rounded up
    end

    it "should obey max_web_dynos" do
      # Check that we are constrained by max_web_dynos
      Dynosaur.plugins[0].stub(:retrieve) { @config["scaler"]["max_web_dynos"]*4 }
      Dynosaur.plugins[1].stub(:retrieve) { 27 }
      combined, details = Dynosaur.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["scaler"]["max_web_dynos"]
    end


    it "should obey min_web_dynos" do
      # Check that we are constrained by min_web_dynos
      Dynosaur.plugins[0].stub(:retrieve) { 0 }
      Dynosaur.plugins[1].stub(:retrieve) { 1 }
      combined, details = Dynosaur.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["scaler"]["min_web_dynos"]
    end
  end

  context "when an error occurs" do
    before do
      @config = get_config_with_test_plugin(1)

      @config["plugins"][0]["interval"] = 0.1
      Dynosaur.initialize(@config)
    end

  end

end
