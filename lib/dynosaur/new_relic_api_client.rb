module Dynosaur
  class NewRelicApiClient
    def initialize(api_key, component_id)
      @api_key = api_key
      @component_id = component_id
    end

    def faraday_connection
      base_url = "https://api.newrelic.com"
      conn = Faraday.new(:url => base_url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def get_metric(metric_name, from: (Time.now - 60), to: Time.now)
        api_path = "/v2/components/#{@component_id}/metrics/data.json"
        now = Time.now.utc
        response = faraday_connection.post(api_path) do |req|
          req.headers['X-Api-Key'] = @new_relic_api_key
          req.body = {
            'names[]' => metric_name,
            'values[]' => 'average_value',
            'summarize' => true,
            'from' => from,
            'to' => to,
          }
        end
        response_data = JSON.parse(response.body)
        return response_data['metric_data']['metrics'][0]['timeslices'][0]['values']['average_value']
    end
  end
end
