require 'spec_helper'

describe "Loading plugins" do
  it "Should load plugin classes" do
    config = get_config_with_test_plugin(1)
    scaler = Dynosaur::Autoscaler.new(config)
    subclasses = Dynosaur::Controllers::AbstractControllerPlugin.subclasses
    subclasses.should include(Dynosaur::Controllers::DynosControllerPlugin)

    input_subclasses = Dynosaur::Inputs::AbstractInputPlugin.subclasses
    input_subclasses.should include(Dynosaur::Inputs::RandomPlugin)
  end

  it "should handle global config" do
    config = get_config_with_test_plugin
    scaler = Dynosaur::Autoscaler.new(config)
    scaler.heroku_app_name.should eql config["scaler"]["heroku_app_name"]
  end

  it "should configure the random plugin" do
    config = get_config_with_test_plugin
    scaler = Dynosaur::Autoscaler.new(config)
    controller_plugins = scaler.controller_plugins
    controller_plugins.length.should eql 1
    controller_plugins[0].input_plugins[0].unit.should eql "randoms"
    controller_plugins[0].input_plugins[0].seed.should eql config["controller_plugins"][0]["input_plugins"][0]["seed"]
  end

  it "should complain for missing config" do
    config = get_config_with_test_plugin
    config["controller_plugins"][0].delete("name")
    expect {
      scaler = Dynosaur::Autoscaler.new(config)
    }.to raise_error("You must specify a name")
  end
end

