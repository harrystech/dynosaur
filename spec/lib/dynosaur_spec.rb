require 'spec_helper'

describe Dynosaur do
  before(:all) do
    config = get_config_with_test_plugin(1)
    Dynosaur.initialize(config)
  end

  describe '#get_status' do
    let(:status) { Dynosaur.get_status }

    it { status.should be_a Hash }
    it { status.should have_key('stopped') }
    it { status['controller_status'].should be_an Array }
    it { status['controller_status'].should_not be_empty }
    it { status['controller_status'].first['results'].should be_empty }

    context 'after a retrieve' do
      before do
        Dynosaur.run_loop
      end
      let(:controller_status) { Dynosaur.get_status['controller_status'].first }
      let(:controller_results) { controller_status['results']['random_0'] }

      it { controller_status.should be_a Hash }
      it { controller_status.should_not be_empty }
      it { controller_status['name'].should eq('Random Plugin') }
      it { controller_results.should be_a Hash }
      it { controller_results.should_not be_empty }
      it { controller_results['health'].should eq('OK') }
      it { controller_results['value'].should be_a Numeric }
    end

    context 'with a stale plugin' do
      before do
        Dynosaur.run_loop

        Timecop.freeze(5.minutes.from_now) do
          rand = Dynosaur.controller_plugins.first.input_plugins.first
          rand.instance_variable_set(:@last_retrieved_ts, 5.minutes.ago)
          rand.stub(:retrieve).and_raise(Exception)
          Dynosaur.run_loop
          @controller_status = Dynosaur.get_status['controller_status'].first
        end

        @controller_results = @controller_status['results']['random_0']
      end

      it { @controller_results['health'].should eq('STALE') }
    end
  end
end
