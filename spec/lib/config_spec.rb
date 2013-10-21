require 'spec_helper'

require 'dynosaur'
require 'pry'

describe "Loading plugins" do
    it "Should load plugin classes" do
        config = get_config_with_test_plugin(0)
        Dynosaur.initialize(config)
        subclasses = ScalerPlugin.subclasses
        subclasses.should include(RandomPlugin)
    end

    it "should handle global config" do
        config = get_config_with_test_plugin
        Dynosaur.initialize(config)
        Dynosaur.heroku_app_name.should eql config["scaler"]["heroku_app_name"]
    end

    it "should configure the random plugin" do
        config = get_config_with_test_plugin
        Dynosaur.initialize(config)
        plugins = Dynosaur.plugins
        plugins.length.should eql 1
        plugins[0].unit.should eql "randoms"
        plugins[0].seed.should eql config["plugins"][0]["seed"]
    end

    it "should complain for missing config" do
        config = get_config_with_test_plugin
        config["plugins"][0].delete("name")
        expect {
            Dynosaur.initialize(config)
        }.to raise_error("You must specify a name")
    end
end

