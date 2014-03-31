require 'spec_helper'

require 'dynosaur'

describe "Plugins" do
  it "should retrieve and cache value properly" do
    config = get_config_with_test_plugin
    config["plugins"][0]["interval"] = 30
    Dynosaur.initialize(config)
    rand = Dynosaur.plugins[0]
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
    Dynosaur.initialize(config)
    rand = Dynosaur.plugins[0]
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
    Dynosaur.initialize(config)
    rand = Dynosaur.plugins[0]

    val = rand.get_value()
    dynos = rand.estimated_dynos
    rand.retrievals.should eql 1  # make sure the value hasn't changed
    dynos.should eql (val / 2.0).ceil
  end

  it "should handle hysteresis properly" do
    config = get_config_with_test_plugin
    config["plugins"][0]["interval"] = 0.05
    config["plugins"][0]["hysteresis_period"] = 0.05*5
    Dynosaur.initialize(config)
    rand = Dynosaur.plugins[0]
    rand.interval.should eql 0.05

    val = rand.get_value()
    dynos = rand.estimated_dynos
    rand.retrievals.should eql 1  # make sure the value hasn't changed
    dynos.should eql (val / 2.0).ceil
    vals = [val]

    buffer_size = rand.recent.max_size

    # Verify that the estimate is based off the last 5 intervals
    10.times do
      sleep 0.05 * 2
      vals << rand.get_value()
      if vals.length > buffer_size
        last_vals = vals[-buffer_size..-1]
      else
        last_vals = vals
      end
      dynos = rand.estimated_dynos
      dynos.should eql (last_vals.max / 2.0).ceil
    end

  end

  it "should provide a config template" do
    t = RandomPlugin.get_config_template
    puts t
  end
end
