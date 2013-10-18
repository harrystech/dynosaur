# Analytics Dyno Scaler

An auto-scaling engine for Heroku web dynos using pluggable API connections.
The first API is Google Analytics Live, which uses the number of active users
on the site to decide how many dynos to run.

## Installation

Add this line to your application's Gemfile:

    gem 'analytics-dyno-scaler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install analytics-dyno-scaler

## Companion Rails App

This engine gem is primarily intended to be run as part of the companion rails
app on a Heroku dyno. That rails app stores the engine config in a database and
runs the decision engine loop in a background thread.

TODO: link to app.

## Usage

In addition to the Rails app, analytics-dyno-scaler comes with a command line
interface that can be configured from a JSON config file.

    analytics-dyno-scaler config.json

The format of the json file is (don't leave comments in JSON)

    {
        // global scaler config
        scaler : {
            heroku_app_name : "foo",
            heroku_api_key : "lkdjekjhdelkjd",
            min_web_dynos : 2,
            max_web_dynos : 20
        },
        plugins : [
            {
                name : "ga",
                type : "ga",
                units : "active users",
                api_private_key : "~/.google/private.p12",
                api_key_passphrase : "notasecret",
                view_id : "6287622972",
                client_email : "your-app@developer.gserviceaccount.com",
                users_per_dyno : 100
            },
            ...
        ]
    }

The CLI program  will run indefinitely, with info output to stdout at intervals.

If multiple plugins are configured, the scaler will use the maximum of all
plugins results (i.e. if your New Relic plugin returns 3, and your GA plugin
returns 5, you should scale to 5 dynos.

## Plugin Configuration

### Google Analytics Configuration

- `api_private_key` : Filename of the p12 private key from the developer console
- `api_key_passphrase` : passphrase to decrypt the private key (optional, only required for encrypted keys)
- `view_id` : The ID of the analytics view you want to monitor.
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

See the Google Analytics plugin for an example.
