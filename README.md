Gemfury
=======

Gemfury is your personal cloud for your private and custom RubyGems.
Once you upload your RubyGem and enable Gemfury as a source, you can
securely deploy any gem to any host. It's simple, reliable, and
hassle-free.

Overview
--------

Gemfury allows you to push your RubyGems to our secure cloud storage
and to deploy them without the need for additional tools or hosting.
Once you [register for a Gemfury account][0], you can start using it by
installing the command-line tool:

    $ sudo gem install gemfury

And subsequently uploading your first Gem:

    $ fury push private-gem-1.0.0.gem

That's it!

Uploading Gems
--------------

Uploading your gems is easy.  Once you've installed the _gemfury_ gem,
upload gems to your account with:

    $ fury push private-gem-1.0.0.gem

If you are migrating from another gem server, or just have many gems
lying around, you can specify a directory path and we will upload
all the gems found in that directory:

    $ fury migrate ./path/to/gems

Deployment
----------

To start installing your gems, you will need to get your secret
Source-URL from your Gemfury Dashboard.  It will look like this:

    https://gems.gemfury.com/j8e6n7n5n3y09/

### Use it with RubyGems command-line

To use it with the regular RubyGems commands, you can add it as a source
with the following command.  This command will store your Gemfury source
in your _~/.gemrc_ file for future use.

    $ gem sources -a https://gems.gemfury.com/j8e6n7n5n3y09/

You can also do a one-time install with:

    $ gem install private-gem --source https://gems.gemfury.com/j8e6n7n5n3y09/

### Use it with Bundler

Using Gemfury with Bundler is simple as well, just add this to your
Gemfile:

    source 'https://gems.gemfury.com/j8e6n7n5n3y09/'

Collaboration
-------------

You can share your Gemfury account with other Gemfury users.  Your
collaborators will be able to upload and remove RubyGems without
access to your Secret-URL or the content of previously uploaded gems.

### Enable collaboration

Collaboration is currently only available via the prerelease
command-line tool.  To get started, you'll need to install it:

    $ sudo gem install gemfury

### Managing collaborators

Only the account owner can manage collaborators.  Collaboration commands
are all grouped under the _sharing_ prefix.  For example, to list the
collaborators for your account:

    $ fury sharing

Adding and removing collaborators is as easy as:

    $ fury sharing:add USERNAME
    $ fury sharing:remove USERNAME

### Impersonation

Once you have been added as a collaborator, you can perform Gem
operations as the shared account via the _--as_ option.  For example,
to upload a new Gem into the shared account:

    $ fury push another-gem-0.1.0.gem --as USERNAME

Same is possible with listing and deleting gems:

    $ fury list --as USERNAME
    $ fury yank another-gem -v 0.1.0 --as USERNAME


Logging-off and more
--------------------

To remove your Gemfury credentials, or to change the current user,
delete _~/.gems/gemfury_ file or run this command:

    $ fury logout

You can also list the Gems in your account.  Unlike _gem list_, this
command only shows the latest releasable version:

    $ fury list

To list all available versions of a gem, use this:

    $ fury versions GEMNAME

You can find out about yanking gems and others commands with:

    $ fury help


Using the API client
--------------------

The API and the API client library (included in this gem as
_Gemfury::Client_) are currently in an unreleased semi-private
undocumented development state.  *Enter at your own peril!*

To start using the client, you'll need to get your API token from
_~/.gem/gemfury_ and initialize the client like so:

``` ruby
client = Gemfury::Client.new(:user_api_key => 'j8e6n7n5n3y09')
```

Given the above-mentioned state of the API, we leave you with the
exercise of figuring out the rest of the library and API :)

Stay tuned...


Contribution and Improvements
-----------------------------

Please email us at support@gemfury.com if we've missed some key functionality or if this gem causes conflicts.  Better yet, fork the code, make the changes (specs too), and submit a pull request to speed things along.

### Dependency conflicts

Over time, dependencies for this gem will get stale and may interfere with your other gems.  Please let us know if you run into this and we will re-test our gem with the new version of the dependency and update the _gemspec_.


Questions
---------

Please email support@gemfury.com or file an Issue if you have any
questions or problems.


Author
------

Michael Rykov :: michael@gemfury.com :: @MichaelRykov

[0]: http://www.gemfury.com/signup