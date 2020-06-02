Gemfury CLI
===========

[![Gem Version](https://badge.fury.io/rb/gemfury.svg)](http://badge.fury.io/rb/gemfury)
[![Build Status](https://secure.travis-ci.org/gemfury/gemfury.svg?branch=master)](https://travis-ci.org/gemfury/gemfury)
[![Code Climate](https://codeclimate.com/github/gemfury/gemfury/badges/gpa.svg)](https://codeclimate.com/github/gemfury/gemfury)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/gemfury)
[![Documentation completeness](https://inch-ci.org/github/gemfury/gemfury.svg?branch=master)](http://inch-ci.org/github/gemfury/gemfury)

This is the Gemfury CLI used to manage your Gemfury packages from the command line.  If you're
familiar with the service and want to jump straight into command line action, please proceed to
the [CLI documentation](https://gemfury.com/help/gemfury-cli).

Gemfury is your personal cloud for your private and custom RubyGems, Python packages, and NPM
modules.  Once you upload your packages and enable Gemfury as a source, you can securely deploy
any package to any host. It's simple, reliable, and hassle-free.


### Introduction to Gemfury
* [Gemfury homepage](https://gemfury.com/)
* [Getting started with Gemfury](https://gemfury.com/help/getting-started)

### Using Gemfury CLI
* [CLI documentation](https://gemfury.com/help/gemfury-cli)
* [Uploading private packages](https://gemfury.com/help/gemfury-cli#uploading-packages)
* [Manage collaborators](https://gemfury.com/help/gemfury-cli#collaboration)

### Putting Gemfury to work
* [Install private RubyGems](https://gemfury.com/help/install-gems)
* [Install private NPM modules](https://gemfury.com/help/npm-registry)
* [Install private Python packages](https://gemfury.com/help/pypi-server)
* [Install private Composer packages](https://gemfury.com/help/php-composer-server)
* [Private RubyGems on Heroku](https://gemfury.com/help/private-gems-on-heroku)


## Using the Gemfury Client

You can also use the client directly via Ruby; you will need a "Full access token" (API token) from `https://manage.fury.io/manage/YOUR-ACCOUNT-NAME/tokens/api`

```ruby
require 'gemfury'

client = Gemfury::Client.new(user_api_key: "YOUR API TOKEN")

all_artifacts = client.list
puts "Available artifacts:"
puts all_artifacts

one_artifact = all_artifacts[0]
puts "Versions of the #{one_artifact['language']} artifact #{one_artifact['name']}:"
artifact_versions = client.versions(one_artifact["name"])
puts artifact_versions.map { |v| v["version"] }
```

More information about the `Gemfury::Client` API is [hosted on rubydoc.info](https://rubydoc.info/gems/gemfury/Gemfury/Client).


## Contribution and Improvements

Please [email us](mailto:support@gemfury.com) if we've missed some key functionality or you have problems installing the CLI client.  Better yet, fork the code, make the changes, and submit a pull request to speed things along.

### Submitting updates

If you would like to contribute to this project, just do the following:

1. Fork the repo on Github.
2. Add your features and make commits to your forked repo.
3. Make a pull request to this repo.
4. Review will be done and changes will be requested.
5. Once changes are done or no changes are required, pull request will be merged.
6. The next release will have your changes in it.

Please take a look at the issues page if you want to get started.

### Feature requests

If you think it would be nice to have a particular feature that is presently not implemented, we would love
to hear that and consider working on it.  Just open an issue in Github.

### Dependency conflicts

Over time, dependencies for this gem will get stale and may interfere with your other gems.  Please let us know if you run into this and we will re-test our gem with the new version of the dependency and update the _gemspec_.


## Questions

Please email support@gemfury.com or file a Github Issue if you have any other questions or problems.
