# Dynosaur

An auto-scaling engine for Heroku web dynos using pluggable API connections.
The first API is Google Analytics Live, which uses the number of active users
on the site to decide how many dynos to run.

## Installation

Add this line to your application's Gemfile:

    gem 'dynosaur'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynosaur

## Companion Rails App

This engine gem is primarily intended to be run as part of the companion rails
app on a Heroku dyno. That rails app stores the engine config in a database and
runs the decision engine loop in a background thread.

TODO: link to app.

## CLI Usage

In addition to the Rails app, dynosaur comes with a command line
interface that can be configured from a JSON config file.

    dynosaur config.yaml

An example config file is included.

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
 - `blackout` (int): Time (in seconds) during which we will not scale **down** after
        any change. This is to prevent rapid cycling up-and-down, whilst still
        allowing rapid increases when required. Default is 300s i.e. 5 minutes.
 - `stats` (boolean): When set to 'true', we output the status as a CSV every
        *interval* seconds.

The CLI program will run indefinitely, with info output to stdout at intervals.

If multiple plugins are configured, the scaler will use the maximum of all
plugins results (i.e. if your New Relic plugin returns 3 dynos, and your GA plugin
returns 5, you should scale to 5 dynos.)

### Statistics

If `stats` is enabled, then a file `./stats.txt` is written every *interval*
seconds. The format is CSV with these columns:

 - time (human readable)
 - time (unix)
 - combined estimate of dynos required
 - actual dynos requested (includes blackout time)
 - dynos before
 - dynos after

## Plugin Configuration

### Google Analytics Configuration

- `api_private_key` : Filename of the p12 private key from the developer console
- `api_key_passphrase` : passphrase to decrypt the private key (optional, only required for encrypted keys)
- `analytics_view_id` : The ID of the analytics view you want to monitor.
- `client_email` : The client email from the developer console.
- `users_per_dyno` : How many users can one dyno handle?

NOTE: the analytics live API is in closed beta as of 2013-10-16.

To retrieve the API credentials, log in to the [Cloud Console](https://cloud.google.com/console#/project) and perform the following steps:

- APIs: enable analytics API
- Registered Apps -> Register App
- Go into new app and generate certificate. Note the password ('notasecret' by
  default)
- Retrieve the generated email and private key

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Writing a Plugin

You'll need to implement the `retrieve()` and `estimated_dynos()` methods.
You can pull any configuration you require from the config hash passed to
`from_config()`.

See the Google Analytics plugin or the toy Random plugin for an example.
