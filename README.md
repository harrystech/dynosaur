# Dynosaur

An auto-scaling engine for Heroku web dynos using pluggable API connections.
The first API is Google Analytics Live, which uses the number of active users
on the site to decide how many dynos to run. There is also a New Relic plugin
that uses the requests per minute.

## Methodology

Each plugin generates a 'value' at some set interval (e.g. polls the GA API
every 10s) and provides a conversion from the value ('active users on the site')
to estimated dynos required. (e.g. 100 active users per dyno). By default this
has some built in hysteresis, i.e.  the plugins are conservative about
decreasing their estimate and report the highest estimate of the past `N`
seconds.

Dynosaur takes the maximum of all plugin estimates, applies a global min/max
constraint and scales your Heroku app to match.

For example, see this plot of a dummy 'Sine wave' plugin (purple line) and the
resulting estimated dynos (orange line).

![Sine wave example](doc/hysteresis_640.png)

The plugin estimates 'units' per dyno,
and Dynosaur is configured with a minimum of 2 dynos. You can see that the
estimated dynos rapidly tracks the upward slopes, but trails the downward slope
by about 30s.

## Installation

If you wish to run standalone, rather than with Dynosaur-Rails:

    $ gem install dynosaur

## CLI Usage

In addition to the Rails app, dynosaur comes with a command line
interface that can be configured from a JSON config file.

    $ dynosaur config.yaml

An example config file and a heroku Procfile is included.

## Global Autoscaler Configuration

The 'scaler' section of the config file configures the main parameters of the
autoscaler.

 - `heroku_app_name` (string): The name of the heroku app you want to autoscale
 - `heroku_api_key` (string): Heroku API key can be retrieved from [the Heroku account settings page.](https://dashboard.heroku.com/account)
 - `min_web_dynos` (int): The minimum number of web dynos we can automatically switch
   to.
 - `max_web_dynos` (int): The maximum number of web dynos we can automatically switch
   to
 - `dry_run` (boolean): If enabled, the scaler does not actually connect to Heroku, just
        simulates the values it would choose. You can analyze the results from
        `stats.txt` after running the command line client.
 - `interval` (int): The autoscaler sleeps for this many seconds before checking for
        activity. Note that each plugin is configured with an API polling
        interval too, so this does not increase the frequency of API polling.
 - `librato_email` (string): Optional, set Librato account to track statistics.
 - `librato_api_key` (string): Optional, set Librato account to track
        statistics.

The CLI program will run indefinitely, with info output to stdout at intervals.

If multiple plugins are configured, the scaler will use the maximum of all
plugins results (i.e. if your New Relic plugin returns 3 dynos, and your GA plugin
returns 5, you should scale to 5 dynos.)

### Statistics

Dynosaur can optionally use [Librato](http://librato.com) to collect some
statistics on its operation. You can start with a free account, and enter the email address and API key in the config.
The following stats are sent every *interval* seconds.

 - combined estimate of dynos required (includes min/max constraints)

For each plugin we send

 - value (e.g. 'active users')
 - plugin dyno estimate

## Plugin Configuration

All plugins have the following config values

- `name` : unique identifier for the plugin instance. Freeform.
- `type` : the name of the plugin class e.g. GoogleAnalyticsPlugin
- `interval` (default 60s) : how often to poll the respective API. (i.e. the retrieved value
  is cached for 'interval' seconds.)
- `hysteresis_period` (default 300s) : the current estimate is based on the
  maximum value observed within this interval. i.e. If the maximum value of
  active users observed in the last 5 minutes is 127, we will base our estimate
  on 127 active users.

### Google Analytics Configuration

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

### New Relic plugin

- `key` : The New Relic API key: [Instructions](https://docs.newrelic.com/docs/features/api-key)
- `appid` : The New Relic App ID (numeric ID, not the name)
- `rpm_per_dyno` : How many requests per minute can one dyno handle?


## Error Reporting

We've added pluggable error handling, with two implementations available so far

### Console (Default)

- Logs errors to the console.

### Email via AWS Simple Email Service

Configured like this in config.yaml

    error_handlers:
        -
        type: Dynosaur::ErrorHandler::Ses
        from: you@example.com
        to: you@example.com
        aws_access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
        aws_secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Writing a Plugin

You'll need to implement the following methods:

`retrieve()`: connect to an API (or wherever) and retrieve a new value. This is
wrapped in a caching layer by the plugin base class.

`value_to_dynos()`: calculate the estimated number of dynos based on the recent
maximum value returned by `retrieve()` (e.g. we use `users_per_dyno` in the GA
plugin). For more fine-grained control, you can override `estimate_dynos()`
instead.

`initialize(config)`: You can pull any configuration you require from the config hash passed in.

See the Google Analytics plugin or the toy Random plugin for an example.

## Contributors

* New Relic plugin by [Jan Lindblom](https://github.com/janlindblom/dynosaur)



[![TravisCI](https://travis-ci.org/harrystech/dynosaur.png)](https://travis-ci.org/harrystech/dynosaur)
