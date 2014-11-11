require 'time'

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
        if Dynosaur.debug
          faraday.response :logger
        end
        faraday.adapter  Faraday.default_adapter
      end
    end

    #
    # It seems like New Relic tends to return 0 if the time window is too small,
    # so default to 10 minutes
    #
    def get_metric(metric_name, from: (Time.now.utc - (60 * 10)).iso8601, to: Time.now.utc.iso8601)
      api_path = "/v2/components/#{@component_id}/metrics/data.json"
      response = faraday_connection.post(api_path) do |req|
        req.headers['X-Api-Key'] = @api_key
        req.body = {
          'names[]' => metric_name,
          'values[]' => 'average_value',
          'summarize' => true,
          'from' => from,
          'to' => to,
        }
      end
      if response.status == 200
        response_data = JSON.parse(response.body)
        return response_data['metric_data']['metrics'][0]['timeslices'][0]['values']['average_value']
      else
        Dynosaur.log "Error retrieving data from New Relic for metric #{metric_name}"
      end
    end
  end
end
