module Resque
  module Plugins
    module UniqueJob
      LOCK_NAME_PREFIX = 'lock'
      RUN_LOCK_NAME_PREFIX = 'running_'

      def lock(*args)
        "#{LOCK_NAME_PREFIX}:#{name}-#{obj_to_string(args)}"
      end

      def run_lock(*args)
        run_lock_from_lock(lock(*args))
      end

      def run_lock_from_lock(lock)
        "#{RUN_LOCK_NAME_PREFIX}#{lock}"
      end

      def lock_from_run_lock(rlock)
        rlock.sub(/^#{RUN_LOCK_NAME_PREFIX}/, '')
      end

      def payload_class(camel_cased_word)
        camel_cased_word = camel_cased_word.to_s

        if camel_cased_word.include?('-')
          camel_cased_word = classify(camel_cased_word)
        end

        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          args = Module.method(:const_get).arity != 1 ? [false] : []

          if constant.const_defined?(name, *args)
            constant = constant.const_get(name)
          else
            constant = constant.const_missing(name)
          end
        end
        constant
      end

      def stale_lock?(lock)
        return false unless get_lock(lock)

        rlock = run_lock_from_lock(lock)
        return false unless get_lock(rlock)

        Resque.working.map {|w| w.job }.map do |item|
          begin
            payload = item['payload']
            klass = payload_class(payload['class'])
            args = payload['args']
            return false if rlock == klass.run_lock(*args)
          rescue NameError
            # unknown job class, ignore
          end
        end
        true
      end

      def ttl
        instance_variable_get(:@unique_lock_autoexpire) || respond_to?(:unique_lock_autoexpire) && unique_lock_autoexpire
      end

      def get_lock(lock)
        lock_value = Resque.redis.get(lock)
        set_time = lock_value.to_i
        if ttl && lock_value && (set_time < Time.now.to_i - ttl)
          Resque.redis.del(lock)
          nil
        else
          lock_value
        end
      end

      def before_enqueue_lock(*args)
        lock_name = lock(*args)
        if stale_lock? lock_name
          Resque.redis.del lock_name
          Resque.redis.del run_lock_from_lock(lock_name)
        end
        not_exist = Resque.redis.setnx(lock_name, Time.now.to_i)
        if not_exist
          if ttl && ttl > 0
            Resque.redis.expire(lock_name, ttl)
          end
        end
        not_exist
      end

      def around_perform_lock(*args)
        # we must calculate the lock name before executing job's perform method, it can modify *args
        jlock = lock(*args)

        rlock = run_lock(*args)
        Resque.redis.set(rlock, Time.now.to_i)

        begin
          yield
        ensure
          Resque.redis.del(rlock)
          Resque.redis.del(jlock)
        end
      end

      def after_dequeue_lock(*args)
        Resque.redis.del(run_lock(*args))
        Resque.redis.del(lock(*args))
      end

      private

      def obj_to_string(obj)
        case obj
        when Hash
          s = []
          obj.keys.sort.each do |k|
            s << obj_to_string(k)
            s << obj_to_string(obj[k])
          end
          s.to_s
        when Array
          s = []
          obj.each { |a| s << obj_to_string(a) }
          s.to_s
        else
          obj.to_s
        end
      end
    end
  end
end
