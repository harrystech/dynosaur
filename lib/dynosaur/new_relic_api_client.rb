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
        #faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    #
    # It seems like New Relic tends to return 0 if the time window is too small,
    # so default to 10 minutes
    #
    def get_metric(metric_name, from: (Time.now.utc - (60 * 10)).iso8601,
                   to: Time.now.utc.iso8601, value_name: 'average_value',
                   summarize: true)
      api_path = "/v2/components/#{@component_id}/metrics/data.json"
      begin
        response = faraday_connection.post(api_path) do |req|
          req.headers['X-Api-Key'] = @api_key
          req.body = {
            'names[]' => metric_name,
            'values[]' => value_name,
            'summarize' => summarize,
          }
          if !from.nil?
            req.body['from'] = from
          end
          if !to.nil?
            req.body['to'] = to
          end
        end
      rescue Faraday::Error::ClientError => e
        raise Dynosaur::ConnectionError, "The New Relic API is unavailable. Message: #{e.message}"
      end

      if response.status == 200
        response_data = JSON.parse(response.body)
        last_timeslice = response_data['metric_data']['metrics'][0]['timeslices'][-1]
        return last_timeslice['values'][value_name]
      else
        puts "Error retrieving data from New Relic for metric #{metric_name}"
        return -1
      end
    end
  end
end
