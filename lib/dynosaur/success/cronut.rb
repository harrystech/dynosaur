require 'faraday'

module Dynosaur::Success
  class Cronut
    CRONUT_API_TOKEN_HEADER = 'X-CRONUT-API-TOKEN'
    PING_INTERVAL = 60

    def initialize(config)
      @host = config["host"]
      @api_token = config["api_token"]
      @public_key = OpenSSL::PKey::RSA.new(config["public_key"].gsub("|", "\n"))
      @cronut_token = config["cronut_token"]
      @last_pinged = nil
    end

    def handle
      # Cronut stores last ping time in the DB, let's not overwhelm it.
      if @last_pinged.present? && (Time.now - @last_pinged) < PING_INTERVAL
        return
      end

      puts "Pinging cronut"
      conn = Faraday.new(@host) do |c|
        c.request :url_encoded
        c.use Faraday::Adapter::NetHttp
        c.headers = {
          CRONUT_API_TOKEN_HEADER => @api_token
        }
      end
      str = "#{Time.now.to_i.to_s}-#{@cronut_token}"
      ping = conn.post "/ping/", {public_id: @public_key.public_encrypt(str)}
      if ping.status != 200
        puts "ERROR: CRONUT RETURNED #{ping.status}"
      end
      @last_pinged = Time.now
    rescue StandardError => e
      puts "ERROR FROM CRONUT: #{e.inspect}"
      puts e.backtrace.join("\n")
    end
  end
end
