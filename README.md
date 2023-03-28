# WebsocketClientLite

Easy to use WebSocket client for Ruby.

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add websocket_client_lite
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install websocket_client_lite
```

## Usage

```ruby
require 'websocket_client_lite'

url = 'wss://echo.websocket.org/'
logger = Logger.new($stdout)
client = WebsocketClientLite.new(url, logger: logger)
return unless client.handshake

client.send_text('hello')
client.each_payload do |payload|
  puts payload
  client.close
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gunyoki/websocket_client_lite.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
