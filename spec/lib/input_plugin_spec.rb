require 'spec_helper'

describe "Input Plugins" do
  it "should retrieve and cache value properly" do
    config = get_config_with_test_plugin
    config["controller_plugins"][0]['input_plugins'][0]['interval'] = 30
    scaler = Dynosaur::Autoscaler.new(config)
    dyno_controller = scaler.controller_plugins[0]
    rand = dyno_controller.input_plugins[0]
    rand.interval.should eql 30.0

    # Retrieve the get_value again before cache times out
    ret0 = rand.retrievals
    val1 = rand.get_value
    rand.retrievals.should eql 1

    val2 = rand.get_value

    val2.should eql val1
    rand.retrievals.should eql 1
  end

  it "should retrieve and re-retrieve value properly" do
    config = get_config_with_test_plugin
    config["controller_plugins"][0]['input_plugins'][0]['interval'] = 0.1
    scaler = Dynosaur::Autoscaler.new(config)
    dyno_controller = scaler.controller_plugins[0]
    rand = dyno_controller.input_plugins[0]
    rand.interval.should eql 0.1

    # retrieve then wait for cache to expire and re-retrieve
    ret0 = rand.retrievals
    val1 = rand.get_value()
    rand.retrievals.should eql 1

    sleep 0.11
    val2 = rand.get_value()

    rand.retrievals.should eql 2
  end

  it "should calculate the resources properly" do
    config = get_config_with_test_plugin
    scaler = Dynosaur::Autoscaler.new(config)
    dyno_controller = scaler.controller_plugins[0]
    rand = dyno_controller.input_plugins[0]

    val = rand.get_value()
    dynos = rand.estimated_resources
    rand.retrievals.should eql 1  # make sure the value hasn't changed
    dynos.should eql (val / 2.0).ceil
  end

  it "should handle hysteresis properly" do
    config = get_config_with_test_plugin
    config["controller_plugins"][0]['input_plugins'][0]['interval'] = 0.05
    config["controller_plugins"][0]["hysteresis_period"] = 0.05*5
    scaler = Dynosaur::Autoscaler.new(config)
    dyno_controller = scaler.controller_plugins[0]
    rand = dyno_controller.input_plugins[0]
    rand.interval.should eql 0.05

    val = rand.get_value()
    dynos = rand.estimated_resources
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
      dynos = rand.estimated_resources
      dynos.should eql (last_vals.max / 2.0).ceil
    end

  end

  context 'health' do
    before do
      config = get_config_with_test_plugin
      config["controller_plugins"][0]['input_plugins'][0]['interval'] = 30
      @scaler = Dynosaur::Autoscaler.new(config)
      @scaler.run_loop
    end
    let(:dyno_controller) { @scaler.controller_plugins[0] }
    let(:rand) { dyno_controller.input_plugins[0] }

    context 'when ok' do
      it "returns ok" do
        expect(rand.health).to eql 'OK'
      end
    end

    context 'when stale' do
      it "returns stale" do
        rand.stub(:retrieve).and_raise(StandardError.new "Dummy Error")
        rand.instance_variable_set(:@last_retrieved_ts, 4.minutes.ago)
        expect(rand.health).to eql 'STALE'
      end
    end
    context 'when outage' do
      it "returns outage" do
        rand.stub(:retrieve).and_raise(StandardError.new "Dummy Error")
        rand.instance_variable_set(:@last_retrieved_ts, 6.minutes.ago)
        expect(rand.health).to eql 'OUTAGE'
      end
    end
  end
end
