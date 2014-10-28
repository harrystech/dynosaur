# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.

require 'pry'
require 'dynosaur'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

def get_config_with_test_plugin(num_plugins=1)
  api_key = SecureRandom.uuid
  app_name = SecureRandom.uuid
  config = {
    "scaler" => {
      "heroku_api_key" => api_key,
      "heroku_app_name" => app_name,
      "dry_run" => true,
      "interval" => 0.1,

    }
  }
  input_plugins = []
  num_plugins.times { |i|
    input_plugins << {
      "name" => "random_#{i}",
      "type" => "Dynosaur::Inputs::RandomPlugin",
      "seed" => 1234,
      "hysteresis_period" => 30,
    }
  }
  config["controller_plugins"] = [{
    'name' => 'Random Plugin',
    'type' => 'Dynosaur::Controllers::DynosControllerPlugin',
    'input_plugins' => input_plugins,
    "min_resource" => 3,
    "max_resource" => 27,
  }]

  return config
end

def stub_redis_memory_usage(fake_value, component_id: 42)
  stub_new_relic_metric("Component/redis/Used Memory[megabytes]", fake_value, component_id)
end

def stub_redis_connection_usage(fake_value, component_id: 42)
  stub_new_relic_metric("Component/redis/Connections[connections]", fake_value, component_id)
end

def stub_new_relic_metric(metric_name, fake_value, component_id)
  fake_response = {
    "metric_data"=>{
      "from"=>"2014-10-28T14:06:43+00:00",
      "to"=>"2014-10-28T14:36:43+00:00",
      "metrics"=>[{
        "name"=>metric_name,
        "timeslices"=>[{
          "from"=>"2014-10-28T14:06:00+00:00",
          "to"=>"2014-10-28T14:35:59+00:00",
          "values"=>{"average_value"=>fake_value}
        }]
      }]
    }
  }
  stubs = Faraday::Adapter::Test::Stubs.new
  test_connection = Faraday.new do |builder|
    builder.adapter :test, stubs do |stub|
      stub.post("/v2/components/#{component_id}/metrics/data.json") { |env| [ 200, {}, fake_response.to_json ]}
    end
  end
  allow_any_instance_of(Dynosaur::NewRelicApiClient).to receive(:faraday_connection).and_return(test_connection)
end


