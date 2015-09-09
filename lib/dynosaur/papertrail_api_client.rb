require 'time'

module Dynosaur
  class PapertrailApiClient
    def initialize(api_key)
      @api_key = api_key
    end

    def faraday_connection
      base_url = "https://papertrailapp.com"
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
    def get_daily_usage
      api_path = "/api/v1/accounts"
      response = faraday_connection.get(api_path) do |req|
        req.headers['X-Papertrail-Token'] = @api_key
        req.headers['Accept'] = 'application/json'
      end
      response_data = JSON.parse(response.body)
      return response_data['log_data_transfer_used']
    end
  end
end
