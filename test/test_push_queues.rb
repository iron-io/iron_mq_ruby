# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'

class TestPushQueues < TestBase

  def setup
    super
  end

  def make_key(i, t, random=0)
    key = "pushq-#{t}-#{i}-#{random}"
  end



  def test_queue_subscriptions

    types = ["multicast", "unicast"]
    types.each do |t|

      puts "Trying type #{t}"

      qname = "subscription-queue-#{t}"

      num_subscribers = 10
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {url: "http://rest-test.iron.io/code/200?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)
      queue = @client.queue(qname)
      p queue
      p queue.subscribers
      assert_equal 10, queue.subscribers.size

      # add the last one
      queue.add_subscriber({url: "http://nowhere.com"})
      queue.reload
      assert_equal 11, queue.subscribers.size
      queue.remove_subscriber({url: "http://nowhere.com"})
      queue.reload
      assert_equal 10, queue.subscribers.size

      # todo: assert subscriptions match

      msg = "hello #{x}"
      m = queue.post(msg)

      puts "sleeping..."
      sleep 10
      puts "Checking results..."
      @rest = Rest::Client.new
      found = 0
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        begin
          response = @rest.get("http://rest-test.iron.io/stored/#{key}")
          parsed = JSON.parse(response.body)
          p parsed['body']
          assert_equal msg, parsed['body']
          found += 1
        rescue Rest::HttpError => ex
          p ex.code
          assert_equal 404, ex.code
        end
      end
      subscribers = queue.messages.get(m.id).subscribers
      p subscribers
      if t == "unicast"
        assert_equal 1, found
        assert_equal 1, subscribers.size
      else # pubsub
        assert_equal num_subscribers, found
        assert_equal num_subscribers, subscribers.size
      end

      subscribers.each do |s|
        p s
        assert_equal 200, s["status_code"]
        assert_equal "deleted", s["status"]
      end
    end

  end

  def test_failure
    @rest = Rest::Client.new
    qname = "failure-queue"

    subscribers = []
    subscribers << {url: "http://rest-test.iron.io/code/503?switch_after=2&switch_to=200"}
    subscribers << {url: "http://rest-test.iron.io/code/503"}

    queue = @client.queue(qname)
    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => "multicast",
                             :retries => 3,
                             :retries_delay => 15
    )
    queue = @client.queue(qname)
    p queue
    p queue.subscribers
    assert_equal 2, queue.subscribers.size

    x = rand(1000)
    msg = "hello #{x}"
    m = queue.post(msg)
    p m

    subscribers = queue.messages.get(m.id).subscribers
    p subscribers
    assert_equal 2, subscribers.size
    subscribers.each do |s|
      p s
      assert_equal 0, s["status_code"]
      assert_equal "queued", s["status"]
    end

    sleep 5

    puts 'getting status'
    subscribers = queue.messages.get(m.id).subscribers
    p subscribers
    assert_equal 2, subscribers.size
    subscribers.each do |s|
      p s
      assert_equal 503, s["status_code"]
      assert_equal "retrying", s["status"]
    end
    puts 'sleeping 20'
    sleep 20
    subscribers = queue.messages.get(m.id).subscribers
    p subscribers
    assert_equal 2, subscribers.size
    subscribers.each_with_index do |s|
      p s
      assert_equal 200, s["status_code"]
      if i == 0
      assert_equal "deleted", s["status"]
      else
      # this one should error out
      assert_equal "error", s["status"]
      end
    end

  end



  def test_202
    types = ["multicast"]
    types.each do |t|

      puts "Trying type #{t}"

      qname = "subscription-queue-#{t}-202"

      num_subscribers = 2
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {url: "http://rest-test.iron.io/code/202?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)
      queue = @client.queue(qname)
      p queue
      p queue.subscribers
      assert_equal 2, queue.subscribers.size
      # todo: assert subscriptions match

      msg = "hello #{x}"
      m = queue.post(msg)

      puts "sleeping..."
      sleep 10

      subscribers = queue.messages.get(m.id).subscribers
      p subscribers
      assert_equal 2, subscribers.size
      subscribers.each do |s|
        p s
        assert_equal 202, s["status_code"]
        assert_equal "reserved", s["status"]
      end

      sleep 60

      subscribers = queue.messages.get(m.id).subscribers
      p subscribers
      assert_equal 2, subscribers.size
      subscribers.each do |s|
        p s
        assert_equal 202, s["status_code"]
        assert_equal "reserved", s["status"]
        # now let's delete it to say we're done with it
        puts "Acking subscriber"
        p s.delete
      end

    end

  end



end

