require 'test/unit'
require 'beanstalk-client'
require 'yaml'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

class BeanstalkTests < TestBase
  def setup
    super

    config = @config['iron']
    beanstalkd_host = "#{@host}:#{config['beanstalkd_port'] || 11300}"
    puts "beanstalkd url: #{beanstalkd_host}"
    @skip = @host.include? 'rackspace'
    return if @skip # bypass these tests if rackspace
    @beanstalk = Beanstalk::Connection.new(beanstalkd_host)
    @beanstalk.put("oauth #{config['token']} #{config['project_id']}")

    clear_tube('default')
  end

  def test_basics
    return if @skip # bypass this test if rackspace
    puts 'test_basics3'

    queue_name = "beanstalk_test"
    clear_queue(queue_name)
    @beanstalk.use(queue_name)
    @beanstalk.watch(queue_name)

    #puts 'reserving...'
    #job = beanstalk.reserve(1)
    #p job
    #exit

    msg = "hello #{Time.now}"
    puts "msg=" + msg
    @beanstalk.put(msg)
    job = @beanstalk.reserve
    p job
    p job.body
    assert_equal msg, job.body, "job.body #{job.body} not the same as the one we put on #{msg}."
    job.delete
    job = assert_raise(Beanstalk::TimedOut) {
      @beanstalk.reserve(1)
    }

    hasher = {:x => 1, :y => "hello", "yo" => "scooby doo"}
    @beanstalk.put(hasher.to_json)
    job = @beanstalk.reserve(1)
    got = JSON.parse(job.body)
    assert got.is_a?(Hash)
    assert_equal hasher[:x], got['x']
    job.delete

    msg = "hello there\nthis is a new line"
    @beanstalk.put(msg)
    job = @beanstalk.reserve(1)
    assert_equal msg, job.body, "#{job.body} does not equal #{msg}"
    job.delete
  end

  def clear_tube(tube)
    return if @skip # bypass this test if rackspace
    watched = @beanstalk.list_tubes_watched(true)
    puts 'watched: ' + watched.inspect
    @beanstalk.watch(tube)
    puts "clear #{tube}"
    # clean up anything in queue
    while x = reserve(0) do
      puts 'deleting ' + x.inspect
      x.delete
    end
    puts 'done clearing'
    @beanstalk.ignore(tube) if not watched.include?(tube)
  end

  def test_basics2
    return if @skip # bypass this test if rackspace
    puts 'test_basics'
    msg = "hello #{Time.now}"
    @beanstalk.put(msg)
    job = reserve
    puts 'first job: ' + job.inspect
    puts "body=" + job.body # prints "hello"
    assert_equal msg, job.body, "body not the same as message."
    job.delete
    puts 'deleted'
    job = reserve(1)
    puts 'second job = ' + job.inspect
    assert job.nil?, "second job was not nil " + job.inspect

    hasher = {:x => 1, :y => "hello", "yo" => "scooby doo"}
    @beanstalk.put(hasher.to_json)
    job = reserve(1)
    got = JSON.parse(job.body)
    puts 'got=' + got.inspect
    assert got.is_a?(Hash)
    assert_equal hasher[:x], got['x']
    job.delete

    msg = "hello there\nthis is a new line"
    @beanstalk.put(msg)
    job = reserve(1)
    assert_equal msg, job.body, "#{job.body} does not equal #{msg}"
    job.delete

    # delete queue on test complete
    resp = @client.queue('default').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_timeout
    return if @skip # bypass this test if rackspace
    puts 'test_timeout'
    msg = "timeout message #{Time.now}"
    # timeout of 10 seconds
    res = @beanstalk.put(msg, 65536, 0, 30)
    puts 'result: ' + res.inspect
    job = reserve(0)
    puts 'first timeout job: ' + job.inspect
    assert_equal msg, job.body, "body not the same as message."

    niljob = reserve(0)
    assert niljob.nil?, "job is not nil! #{niljob.inspect}"

    # let it time out
    sleep 30
    job = reserve(0)
    puts 'second delayed job: ' + job.inspect
    assert_not_nil job, "job is nil"
    assert_equal msg, job.body, "body not the same as message."
    job.delete

    # delete queue on test complete
    resp = @client.queue('default').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_delay
    return if @skip # bypass this test if rackspace
    puts 'test_delay'
    msg = "delayed message #{Time.now}"
    # delay of 2 seconds
    @beanstalk.put(msg, 65536, 2)

    # delay should still be in effect, so job is nil
    job = reserve(0)
    assert job.nil?, "job is not nil"

    # wait for delay to expire
    sleep 3
    job = reserve(0)
    assert_not_nil job, "job is nil"
    assert_equal msg, job.body, "body not the same as message."
    job.delete

    # delete queues on test complete
    resp = @client.queue('default').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def tube_message(tube)
    return if @skip # bypass this test if rackspace
    "hello #{tube}! #{Time.now}"
  end

  def reserve(timeout=nil)
    return if @skip # bypass this test if rackspace
    begin
      job = @beanstalk.reserve(timeout)
      LOG.info 'got job: ' + job.inspect
      job
    rescue Beanstalk::TimedOut => ex
      puts "Timed out: #{ex.message}"
      nil
    end
  end

  def test_tubes
    return if @skip # bypass this test if rackspace
    clear_tube('youtube')
    tube1 = 'default'
    msg1 = tube_message(tube1)
    @beanstalk.put(msg1)
    tube2 = 'youtube'
    @beanstalk.use(tube2) # switch tubes to put messages on
    msg2 = tube_message(tube2)
    @beanstalk.put(msg2)
                          # now we have a single message in two different tubes.
                          # let's first try to ensure we only get the one off the default tube.
    job = reserve(1)
    assert_equal msg1, job.body, "body #{job.body.to_s} does not equal #{msg1}"
    job.delete
                          # second message should not come off since we're not watching that tube.
    job = reserve(1)
    assert job.nil?, "second job was not nil " + job.inspect

    @beanstalk.watch(tube2)
    job = reserve(1)
    assert_equal msg2, job.body, "body #{job.body.to_s} does not equal #{msg2}"
    job.delete

    # Now that we're watching both tubes we should get messages put into either.
    @beanstalk.use(tube1)
    msg3 = tube_message(tube1)
    @beanstalk.put(msg3)
    job = reserve(1)
    assert_equal msg3, job.body
    job.delete

    # now put one in default and one in tube2, then we'll ignore default
    msg1 = tube_message(tube1)
    @beanstalk.put(msg1)
    @beanstalk.use(tube2) # switch tubes to put messages on
    msg2 = tube_message(tube2)
    @beanstalk.put(msg2)

    @beanstalk.ignore(tube1)
    job = reserve(1)
    assert_equal msg2, job.body, "body #{job.body.to_s} does not equal #{msg2}"
    job.delete
    job = reserve(1)
    assert job.nil?

    # clean up the last message from default
    @beanstalk.watch(tube1)
    job = reserve(1)
    assert_equal msg1, job.body, "body #{job.body.to_s} does not equal #{msg1}"
    job.delete

    # delete queues on test complete
    resp = @client.queue('youtube').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"

    resp = @client.queue('beanstalk_test').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"

    resp = @client.queue('default').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


end
