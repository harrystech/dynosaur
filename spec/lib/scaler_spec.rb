
# Test the main scaler logic

require 'spec_helper'

describe "scaler" do
  it "should run the loop and modify settings" do

    # The scaler checks every 0.1s
    config = get_config_with_test_plugin

    # The plugin may change every 0.2s
    config["controller_plugins"][0]["interval"] = 0.2
    Dynosaur.initialize(config)
    dyno_controller = Dynosaur.controller_plugins[0]

    puts "starting autoscaler"
    thread = Dynosaur.start_in_thread

    3.times { |i|
      sleep 0.11  # sleep for one tick of the scaler
      estimated = dyno_controller.current_estimate
      current = dyno_controller.current
      puts "#{i*0.11}s: Estimated = #{estimated}; Current = #{current}"
      current.should be > 0
      (current >= estimated).should be true
    }
    puts "Stopping autoscaler"
    Dynosaur.stop_autoscaler
    thread.join
  end


  context "given multiple plugin configs" do
    before do
      @config = get_config_with_test_plugin(2)

      @config["controller_plugins"][0]['input_plugins'][0]["interval"] = 0.1
      @config["controller_plugins"][0]['input_plugins'][1]["interval"] = 0.1
      Dynosaur.initialize(@config)
    end


    it "should pick the maximum estimate" do
      dyno_controller = Dynosaur.controller_plugins[0]
      dyno_controller.input_plugins[0].stub(:retrieve) { 10 }
      dyno_controller.input_plugins[1].stub(:retrieve) { 33 }
      combined, details = dyno_controller.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql 17  # 33 / 2 rounded up
    end

    it "should obey max_web_dynos" do
      # Check that we are constrained by max_web_dynos
      dyno_controller = Dynosaur.controller_plugins[0]
      dyno_controller.input_plugins[0].stub(:retrieve) { @config["controller_plugins"][0]["max_web_dynos"]*4 }
      dyno_controller.input_plugins[1].stub(:retrieve) { 27 }
      combined, details = dyno_controller.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["controller_plugins"][0]["max_web_dynos"]
    end


    it "should obey min_web_dynos" do
      # Check that we are constrained by min_web_dynos

      dyno_controller = Dynosaur.controller_plugins[0]
      dyno_controller.input_plugins[0].stub(:retrieve) { 0 }
      dyno_controller.input_plugins[1].stub(:retrieve) { 1 }
      combined, details = dyno_controller.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["controller_plugins"][0]["min_web_dynos"]
    end
  end

  context "when an error occurs" do
    before do
      @config = get_config_with_test_plugin(1)

      @config["controller_plugins"][0]["interval"] = 0.1
      Dynosaur.initialize(@config)
    end

    it "should report the error" do
      dyno_controller = Dynosaur.controller_plugins[0]
      rand = dyno_controller.input_plugins[0]
      rand.should_receive(:retrieve).at_least(:once) { raise Exception.new "Oh Noes!" }
      ErrorHandler.should_receive(:report).at_least(:once)
      dyno_controller.get_combined_estimate
    end
  end

end
