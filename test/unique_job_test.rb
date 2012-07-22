require 'test/unit'
require 'resque'
require 'resque/plugins/unique_job'

class UniqueJobTest < Test::Unit::TestCase
  class Job
    extend Resque::Plugins::UniqueJob
    @queue = :job_test
    def self.perform(param) ; end
  end

  class AutoexpireLockJob
    extend Resque::Plugins::UniqueJob
    @queue = :job_test
    @unique_lock_autoexpire = 1
    def self.perform(param) ; end
  end

  def setup
    Resque.remove_queue(Resque.queue_from_class(Job))
    Resque.redis.keys('*:UniqueJobTest::*').each {|k| Resque.redis.del(k) }
  end

  def test_no_more_than_one_job_instance
    queue = Resque.queue_from_class(Job)

    3.times { Resque.enqueue(Job, "hello") }
    assert_equal 1, Resque.size(queue)

    3.times { Resque.enqueue(Job, "bye") }
    assert_equal 2, Resque.size(queue)
  end

  def test_lock_is_removed_after_job_run
    queue = Resque.queue_from_class(Job)
    Resque.enqueue(Job, "hello")
    assert_equal 1, Resque.size(queue)

    worker = Resque::Worker.new(queue)
    job = worker.reserve
    worker.perform(job)
    assert_equal 0, Resque.size(queue)

    Resque.enqueue(Job, "hello")
    assert_equal 1, Resque.size(queue)
  end


  def test_autoexpire_lock
    Resque.enqueue(AutoexpireLockJob, 123)
    sleep 2
    Resque.enqueue(AutoexpireLockJob, 123)
    assert_equal 2, Resque.size(Resque.queue_from_class(AutoexpireLockJob))
  end

end
