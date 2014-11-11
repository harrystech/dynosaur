
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'dynosaur/version'
require 'dynosaur/error_handler'

#
# InputPlugin implementation that uses Google Analytics Live API
# to get the current active users on the site
#
module Dynosaur
  module Inputs
    class GoogleAnalyticsInputPlugin < AbstractInputPlugin
      API_VERSION = "v3"
      CACHED_API_FILE = "analytics-#{API_VERSION}.cache"
      KEYFILE = File.expand_path('~/.google/private.p12')
      PASSPHRASE = 'notasecret'

      # Load config from the config hash
      def initialize(config)
        super
        @unit = "active users"
        @keyfile = config.fetch("keyfile", KEYFILE)
        @passphrase = config.fetch("passphrase", PASSPHRASE)
        @keytext = config.fetch("key", "")
        @client_email = config["client_email"]
        @analytics_view_id = config["analytics_view_id"]
        @users_per_dyno = config["users_per_dyno"].to_i

        if @client_email.nil?
          raise "You must supply client_email in the google analytics plugin config"
        end
        if @analytics_view_id.nil?
          raise "You must supply analytics_view_id in the google analytics plugin config"
        end
        if @users_per_dyno.nil?
          raise "You must supply users_per_dyno in the google analytics plugin config"
        end

        init_api

      end

      def self.get_config_template
        t = {
          "client_email" => ["text"],
          "key" => ["textarea", "42", "27" ],
          "analytics_view_id" => ["text"],
          "users_per_dyno" => ["text"]
        }
        return t
      end

      def retrieve
        return get_active_users
      end

      def value_to_resources(value)
        return (value / @users_per_dyno.to_f).ceil
      end

      private
      def init_api
        @client = Google::APIClient.new(
          :application_name => "Analytics Dyno Scaler",
          :application_version => Dynosaur::VERSION)
        @client.authorization = nil
        if @keytext  # load key from string
          Dynosaur.log "Loading key from PEM text"
          @key = OpenSSL::PKey::RSA.new(@keytext)
        else  # load key from encrypted file
          Dynosaur.log "Loading key from file #{@keyfile}"
          @key = Google::APIClient::KeyUtils.load_from_pkcs12(@keyfile, @passphrase)
        end
        @analytics = nil

        # Load cached discovered API, if it exists. This prevents retrieving the
        # discovery document on every run, saving a round-trip to the discovery service.
        if File.exists? CACHED_API_FILE
          File.open(CACHED_API_FILE) do |file|
            @analytics = Marshal.load(file)
          end
        else
          @analytics = @client.discovered_api('analytics', API_VERSION)
          File.open(CACHED_API_FILE, 'w') do |file|
            Marshal.dump(@analytics, file)
          end
        end
      end

      def authorize(force=false)
        # Check for re-authorization
        if !@client.authorization.nil? && !force
          expiry = @client.authorization.issued_at + @client.authorization.expiry*60
          reauth_time = expiry - 2
          now = Time.now
          if now < reauth_time
            return  # Skip authorization
          end
        end
        @client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => 'https://www.googleapis.com/auth/analytics.readonly',
          :issuer => @client_email,
          :signing_key => @key)
        # Request a token for our service account
        @client.authorization.fetch_access_token!
      end

      def get_active_users
        active = -1
        begin
          authorize
          r = @client.execute(:api_method => @analytics.data.realtime.get, :parameters => { 'ids' => "ga:#{@analytics_view_id}", 'metrics' => 'ga:activeVisitors'})

          if r.data.totalResults == 0
            return 0
          end
          active = r.data.rows[0][0].to_i
        rescue Exception => e
          ErrorHandler.report(e)
          Dynosaur.log "ERROR: failed to decipher result, forcing re-auth"
          Dynosaur.log e.inspect
          begin
            authorize(true)
          rescue Exception => e
            ErrorHandler.report(e)
          end
        end
        return active
      end
    end
  end # Inputs
end # Dynosaur
