# Feature Flags in Ruby Sinatra

[Feature flags](https://www.optimizely.com/optimization-glossary/feature-flags/?) enable a powerful continuous delivery process and provide a platform for [progressive delivery](https://www.optimizely.com/optimization-glossary/progressive-delivery/) with phased rollouts and [A/B tests](https://www.optimizely.com/optimization-glossary/ab-testing/).

However, building a feature flagging system is usually not your company's core competency and can be a distraction from other development efforts.

In this step-by-step lab, you'll see how to integrate feature flags into your Ruby Sinatra application with a
free version of Optimizely, [Optimizely Rollouts](https://www.optimizely.com/rollouts-signup/?utm_source=labs&utm_campaign=asa-sinatra-flags-lab).

## Pre-requisites
 [Ruby 2.3](https://www.ruby-lang.org/en/documentation/installation/)

## Steps

### 1. Create a Ruby Sinatra Application

If you already have a Ruby application feel free to skip to step 2. Otherwise, follow the instructions to start a new Ruby Sinatra application:

Create a file called `myapp.rb` and paste the following contents:

```ruby
# myapp.rb
require 'sinatra'

get '/' do
  'Hello world!'
end
```

Install the Sinatra ruby gem on the command-line with:

```bash
gem install sinatra
```

Run the application from the command-line with:
```bash
ruby myapp.rb
```

Find the port number that is displayed by your running server
...
[2020-06-11 14:29:43] INFO  WEBrick::HTTPServer#start: pid=37152 port=**4567**
...

Open a browser to see your server running at http://localhost:4567 with the message "Hello World!":

![Screenshot](https://raw.githubusercontent.com/optimizely/labs/master/labs/feature-flags-ruby-sinatra/screenshots/app.png)

### 2. Setup the Feature Flag Interface

Create a free Optimizely Rollouts account [here](https://www.optimizely.com/rollouts-signup/?utm_source=labs&utm_campaign=asa-sinatra-flags-lab).

In the Rollouts interface, navigate to 'Features > Create New Feature' and create a feature flag called 'hello_world':

![Screenshot](https://raw.githubusercontent.com/optimizely/labs/master/assets/optimizely-screenshots/create-flag.gif)

To connect your 'hello_world' feature to your application, find your SDK Key. Navigate to the far left 'Settings' > 'Environments' and copy the Development SDK Key value.

![Screenshot](https://raw.githubusercontent.com/optimizely/labs/master/assets/optimizely-screenshots/sdk-key.gif)

### 3. Install the Optimizely Rollouts Ruby SDK

The Ruby SDK allows you to setup feature toggles from within your codebase.

Install the Optimizely gem from the command-line with:

```
gem install optimizely-sdk
```

Create a new file `optly.rb` in the root of your new application. If you followed the Sinatra instructions above, the `optly.rb` file should be in the same directory as `myapp.rb`

Import the SDK and initialize a singleton instance of the [Optimizely SDK](https://github.com/optimizely/ruby-sdk) by placing the following code in your new `optly.rb` file (be sure to replace <Your_SDK_Key> with your actual SDK key):

```ruby
# optly.rb
require 'singleton'
require 'logger'
require 'optimizely/optimizely_factory'

class Optly
  include Singleton

  def initialize
    sdk_key = '<Your_SDK_Key>'

    logger = Optimizely::SimpleLogger.new(Logger::INFO)

    config_manager = Optimizely::HTTPProjectConfigManager.new(
      sdk_key: sdk_key,
      polling_interval: 10,
      blocking_timeout: 10,
      logger: logger,
    )

    @client = Optimizely::OptimizelyFactory.custom_instance(
      sdk_key,          # sdk_key
      nil,              # datafile
      nil,              # event_dispatcher
      logger,           # logger
      nil,              # error_handler
      false,            # skip_json_validation
      nil,              # user_profile_service
      config_manager,   # config_manager
      nil               # notification_center
    )
  end

  def client
    @client
  end
end
```

A singleton as we defined it above allows you to use Optimizely anywhere within your Ruby application you want.

Require the Optimizely singleton instance in your Ruby application by adding `require './optly'` in `myapp.rb`:

```ruby
# myapp.rb
require 'sinatra'
require './optly' # Imports the Optimizely singleton

get '/' do
  'Hello world!'
end
```

### 4. Implement the Feature Flag

To implement your 'hello_world' feature flag, use the is_feature_enabled method on the optimizely client instance:


```ruby
  enabled = Optly.instance.client.is_feature_enabled('hello_world', 'user123', {
    'customerId' => 123,
    'isVIP' =>  true
  })

  enabled ? 'Hello World! You got the hello_world feature!' : 'You did not get the hello_world feature'
```

Note that `is_feature_enabled` takes three parameters. The first is used to identify the feature you created in the Optimizely application. The next two are associated with visitors to your application:

* **userId**: a string used for random percentage rollouts across your users. This can be any string that uniquely identifies a particular user. In this case, `user123` is just a hard-coded example of what might come from your user table database.
* **userAttributes**: a hash of key, value attributes used for targeting rollouts across your users. In this case,
  `customerId` and `isVIP` are just examples.

To read more about the API and its parameters, see [this documentation page](https://docs.developers.optimizely.com/full-stack/docs/is-feature-enabled-ruby#section-parameters).

Your full code in `myapp.rb` should look like the following:

```ruby
# myapp.rb
require 'sinatra'
require './optly'

get '/' do
  enabled = Optly.instance.client.is_feature_enabled('hello_world', 'user123', {
    'customerId' => 123,
    'isVIP' =>  true
  })

  enabled ? 'Hello World! You got the hello_world feature!' : 'You did not get the hello_world feature'
end
```

### 5. Turn the Feature Toggle on!

If you save and re-run your application now, you'll notice that you did not get the feature. This is because the feature is not enabled, which means it's off for all visitors to your application.

To turn on the feature:
1. Log-in to the Optimizely project where you made your hello_world feature
2. Navigate to Features
3. Click on the 'hello_world' feature
4. Change to the 'Development' environment to match the SDK Key we used
5. Roll the feature out to ensure it is set to 100% for everyone
6. Click Save to save your changes

In less than 1 min, refreshing your Ruby app should now show the feature toggled on and you should see "Hello world! You got the hello_world feature!".

Congrats! You've implemented a feature flag in a Ruby Sinatra application. Hope you've enjoyed this lab!
