# resque-uniq

A Resque plugin to ensure only one job instance is queued or running at a time

## Installation

Add this line to your application's Gemfile:

    gem 'resque-uniq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-uniq

## Usage

Make your job class extend `Resque::Plugins::UniqueJob`, like this

    class BigJob
      extend Resque::Plugins::UniqueJob  # <--- add this line
      @queue = :big_job

      def self.perform
        # ...
      end
    end

## Credits

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
