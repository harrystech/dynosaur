
# Web Dyno Autoscaling

There are two input plugins available: Google Analytics Live API (we define a number of users per dyno) and New Relic RPM API (define requests per minute that one dyno can handle). If both plugins are configured, Dynosaur will use the highest estimate and scale your dynos to match.


<pre>
controller_plugins:
    -
        name: dynos
        type: Dynosaur::Controllers::DynosControllerPlugin
        min_web_dynos: <%= ENV.fetch('MIN_WEB_DYNOS', 2) %>
        max_web_dynos: <%= ENV.fetch('MAX_WEB_DYNOS', 15) %>
        input_plugins:
            -
                name: ga
                type: Dynosaur::Inputs::GoogleAnalyticsInputPlugin
                interval: 10     # Do not go below 10s, the API limit will kick in!
                client_email: <%= ENV['GOOGLE_CLIENT_EMAIL'] %>
                analytics_view_id: 123456789
                users_per_dyno: 210
                key: <%= ENV.fetch('GA_PRIVATE_KEY', "").gsub("\n", "|") %>
            -
                name: newrelic
                type: Dynosaur::Inputs::NewRelicPlugin
                interval: 10
                key: <%= ENV["NEW_RELIC_API_KEY"] %>
                appid: 1234567
                rpm_per_dyno: 400
                hysteresis_period: 60
</pre>

## Global Config

- `name` (string): not important, used in Librato metric name so avoid spaces.
- `type: Dynosaur::Controllers::DynosControllerPlugin`
- `min_web_dynos` (int): Never scale below this many dynos
- `max_web_dynos` (int): Never scale above this many dynos

## Google Analytics Configuration

- `type: Dynosaur::Inputs::GoogleAnalyticsInputPlugin`
- `key` : The non-encrypted PEM representation of the private key (see below)
- `analytics_view_id` : The ID of the analytics view you want to monitor.
- `client_email` : The client email from the developer console.
- `users_per_dyno` : How many users can one dyno handle?

**NOTE: the analytics live API is in closed beta as of 2014-01-03.**

To retrieve the API credentials, log in to the [Cloud Console](https://cloud.google.com/console#/project) and perform the following steps:

- APIs: enable analytics API
- Credentials: generate an OAuth 'service account' with a certificate. Note the key passphrase ('notasecret' by
  default)
- Retrieve the generated email address and private key for the service account

Convert the encrypted pkcs12 file to an unencrypted ASCII private key:

    $ openssl pkcs12 -in foo.p12 -nodes -clcerts

- Use the output between -----BEGIN RSA PRIVATE KEY and -----END RSA PRIVATE KEY
  (including those lines) as the value for `key`

In the Analytics admin console:

- Under "User Management" in either property or view sections, add the service account you just created as an
	authorized user with 'Read and Analyze' permissions.
- Retrieve the view ID under 'View->View Settings'

## New Relic plugin

- `key` : The New Relic API key: [Instructions](https://docs.newrelic.com/docs/features/api-key)
- `appid` : The New Relic App ID (numeric ID, not the name)
- `rpm_per_dyno` : How many requests per minute can one dyno handle?
