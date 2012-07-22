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

## How it works

_resque-uniq_ associates a unique lock with each job instance being enqueued. A lock is a simple Redis _key/value_ pair.
The key name is derived uniquely from the job class name and job args. The value is `Time.now.to_i`. If the lock already
exists a new job instance is not enqueued. If not a new lock is created and a job is enqueued. The lock is removed after
its job's `perform` method has finished.

There is another lock, called _run lock_, which is being held during the execution of `perform` method. Before enqueuing
a new job instance, _resque-uniq_ checks if there is any orphaned _run lock_. This way it can detect if Resque workers
have crashed during job execution and left behind stale locks.

You can tell _resque-uniq_ to auto-expire job locks by setting `@unique_lock_autoexpire`

    class BigJob
      extend Resque::Plugins::UniqueJob
      @queue = :big_job
      @unique_lock_autoexpire = 6 * 3600   # TTL = 6 hours

      def self.perform
        # ...
      end
    end

This is usually not necessary, but you can if you want.

## Credits

There are several similar Resque plugins. We tried them all but for one reason or another they don't work reliably
for us. We wrote our own version which we think works better for us. Nonetheless we would like to thank the authors
of those plugins for inspiration.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
