
# Test the main scaler logic

require 'spec_helper'

describe "scaler" do

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

    it "should obey max_resource" do
      # Check that we are constrained by max_resource
      dyno_controller = Dynosaur.controller_plugins[0]
      dyno_controller.input_plugins[0].stub(:retrieve) { @config["controller_plugins"][0]["max_resource"]*4 }
      dyno_controller.input_plugins[1].stub(:retrieve) { 27 }
      combined, details = dyno_controller.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["controller_plugins"][0]["max_resource"]
    end


    it "should obey min_resource" do
      # Check that we are constrained by min_resource

      dyno_controller = Dynosaur.controller_plugins[0]
      dyno_controller.input_plugins[0].stub(:retrieve) { 0 }
      dyno_controller.input_plugins[1].stub(:retrieve) { 1 }
      combined, details = dyno_controller.get_combined_estimate
      puts "#{combined} - #{details}"
      combined.should eql @config["controller_plugins"][0]["min_resource"]
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
      expect(rand).to receive(:retrieve).at_least(:once).and_raise(StandardError.new "Oh Noes!")
      expect(Dynosaur::ErrorHandler).to receive(:handle).at_least(:once)
      dyno_controller.get_combined_estimate
    end
  end

end
