# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'

class TestPushQueues < TestBase

  def setup
    super
  end

  #def test_queue_subscriptions
  #
  #  types = ["pubsub", "workers"]
  #  types.each do |t|
  #
  #    qname = "subscription-queue-#{t}"
  #
  #    num_subscribers = 10
  #    subscribers = []
  #    num_subscribers.times do |i|
  #      key = make_key(i, t)
  #      subscribers << {url: "http://rest-test.iron.io/code/200?store=#{key}"}
  #    end
  #
  #    queue = @client.queue(qname)
  #    res = queue.update(:subscribers => subscribers,
  #                       :push_type => t)
  #    queue = @client.queue(qname)
  #    p queue
  #    p queue.subscribers
  # assert_equal 10, queue.subscribers.size
  #    # todo: assert subscriptions match
  #
  #    x = rand(1000)
  #    msg = "hello #{x}"
  #    queue.post(msg)
  #
  #    puts "sleeping..."
  #    sleep 10
  #    puts "Checking results..."
  #    @rest = Rest::Client.new
  #    found = 0
  #    num_subscribers.times do |i|
  #      key = make_key(i, t)
  #      begin
  #        response = @rest.get("http://rest-test.iron.io/stored/#{key}")
  #        parsed = JSON.parse(response.body)
  #        p parsed['body']
  #        assert_equal msg, parsed['body']
  #        found += 1
  #      rescue Rest::HttpError => ex
  #        p ex.code
  #        assert_equal 404, ex.code
  #      end
  #    end
  #    if t == "workers"
  #      assert_equal 1, found
  #    else # pubsub
  #      assert_equal num_subscribers, found
  #    end
  #  end
  #
  #end

  def make_key(i, t)
    key = "pushq-#{t}-#{i}"
  end

  def test_failure
    @rest = Rest::Client.new
    qname = "failure-queue"

    subscribers = []
    subscribers << {url: "http://rest-test.iron.io/code/503?switch_after=2&switch_to=200"}

    queue = @client.queue(qname)
    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => "pubsub",
                             :retries => 3,
                             :retries_delay => 15
    )
    queue = @client.queue(qname)
    p queue
    p queue.subscribers
    assert_equal 1, queue.subscribers.size

    x = rand(1000)
    msg = "hello #{x}"
    m = queue.post(msg)
    p m

    subscribers = queue.messages.get(m.id).subscribers
    p subscribers
    assert_equal 1, subscribers.size
    subscribers.each do |s|
      p s
      assert_equal 0, s["status_code"]
      assert_equal "queued", s["status"]
    end

    sleep 5

    puts 'getting status'
    subscribers = queue.messages.get(m.id).subscribers
    p subscribers
    assert_equal 1, subscribers.size
    subscribers.each do |s|
      p s
      assert_equal 503, s["status_code"]
      assert_equal "error", s["status"]
    end
    puts 'sleeping 20'
    sleep 20
    subscribers = queue.messages.get(subscribers.id).subscribers
    p subscribers
    assert_equal 1, subscribers.size
    subscribers.each do |s|
      p s
      assert_equal 200, s["status_code"]
      assert_equal "complete", s["status"]
    end

  end

end

