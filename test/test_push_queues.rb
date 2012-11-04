# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'

class TestPushQueues < TestBase

  def setup
    super
  end

  #def test_message_subscriptions
  #  res = @client.messages.post("hello world!", :subscriptions=>["http://requestb.in/oui4adou"])
  #  assert res.id
  #  post_id = res.id
  #  assert res.msg
  #  p res
  #end

  def test_queue_subscriptions

    types = ["pubsub", "workers"]
    types.each do |t|

      qname = "subscription-queue-#{t}"

      num_subscribers = 10
      subscribers = []
      num_subscribers.times do |i|
        key = make_key(i, t)
        subscribers << "http://rest-test.iron.io/code/200?store=#{key}"
      end

      queue = @client.queue(qname)
      res = queue.update(:subscriptions => subscribers,
                         :push_type => t)
      queue = @client.queue(qname)
      p queue
      p queue.subscriptions

      x = rand(1000)
      msg = "hello #{x}"
      queue.post(msg)

      puts "sleeping..."
      sleep 10
      puts "Checking results..."
      @rest = Rest::Client.new
      found = 0
      num_subscribers.times do |i|
        key = make_key(i, t)
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
      if t == "workers"
        assert_equal 1, found
      else # pubsub
        assert_equal num_subscribers, found
      end
    end

  end

  def make_key(i, t)
    key = "pushq-#{t}-#{i}"
  end

end

