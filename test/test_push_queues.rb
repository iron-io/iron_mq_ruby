# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'

class TestPushQueues < TestBase

  def setup
    super
    @client.queue_name = 'ironmq-gem-quick'
  end

  def test_message_subscriptions
    res = @client.messages.post("hello world!", :subscriptions=>["http://requestb.in/oui4adou"])
    assert res.id
    post_id = res.id
    assert res.msg
    p res
  end

  def test_queue_subscriptions
    qname = "subscription-queue"
    res = @client.queues.post(:queue_name=>qname, :subscriptions=>["http://requestb.in/1lhkwk31", "http://requestb.in/1icckwe1"])
    q = @client.queues.get(:queue_name=>qname)
    p q
    p q["subscriptions"]

    @client.messages.post("hello sub queue", :queue_name=>qname)


  end

end

