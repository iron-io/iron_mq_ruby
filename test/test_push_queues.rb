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
    qname = "subscription-queue"

    num_subscribers = 2
    subscribers = []
    num_subscribers.times do |i|
      subscribers << "http://rest-test.iron.io/code/200?store=pushq#{i}"
    end

    queue = @client.queue(qname)
    res = queue.update(:subscriptions => subscribers,
                       :push_type => "pubsub")
    queue = @client.queue(qname)
    p queue
    p queue.subscriptions

    x = rand(1000)
    msg = "hello #{x}"
    queue.post(msg)

    puts "sleeping..."
    sleep 5
    puts "Checking results..."
    @rest = Rest::Client.new
    num_subscribers.times do |i|
      begin
        response = @rest.get("http://rest-test.iron.io/stored/pushq#{i}")
        parsed = JSON.parse(response.body)
        p parsed
        assert_equal msg, parsed['body']
      rescue Rest::HttpError => ex
        p ex.code
      end
    end
    # assert_equal msg, post_body

  end

end

