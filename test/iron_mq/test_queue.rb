gem 'minitest'
require 'minitest/autorun'

require 'helpers'

class TestQueue < Minitest::Test
  include Helpers

  BASIC_FIELDS = %i(name project_id type message_timeout message_expiration)

  def setup
    @client = IronMQ::Client.new
    @qname = 'brave-new-v3-queue'
    remake_default_queue
  end

  def teardown
    delete_queue(@client, @qname)
  end

  def remake_default_queue
    delete_queue(@client, @qname)
    @queue = @client.queue(@qname)
  end

  def assert_basic_fields_exist(queue)
    BASIC_FIELDS.each { |f| refute_nil queue.public_send(f) }
  end

  def test_create_queue
    @queue.create!
    assert_basic_fields_exist @queue

    remake_default_queue

    msg_timeout = 77
    msg_expire = 1234
    resp = @queue.create!(message_timeout: msg_timeout,
                          message_expiration: msg_expire)
    assert_response resp, 'queue'
    assert_basic_fields_exist @queue
    assert_equal msg_timeout, @queue.message_timeout
    assert_equal msg_expire, @queue.message_expiration

    remake_default_queue

    subs = make_subscribers(3)
    resp = @queue.create!(push: {subscribers: subs})
    assert_response resp, 'queue'
    assert_basic_fields_exist @queue
    assert @queue.push_queue?
    assert_subscribers_equal subs, @queue.subscribers
  end

  def test_get_info
    q = IronMQ::Queue.new(@client, @qname)
    resp = q.create!
    assert_response resp, 'queue'
    assert_basic_fields_exist q

    qinfo = @queue.get_info!
    assert_instance_of Hash, qinfo
    assert_equal q, @queue

    remake_default_queue

    assert_raises(Rest::HttpError) { @queue.get_info! }
  end

  def test_update
    resp = @queue.create!
    assert_response resp, 'queue'
    assert_basic_fields_exist @queue

    msg_expire = 9999
    resp = @queue.update!(message_expiration: msg_expire)
    assert_response resp, 'queue'
    assert_basic_fields_exist @queue
    assert_equal msg_expire, @queue.message_expiration
  end

  def test_delete
    resp = @queue.create!
    assert_response resp, 'queue'
    assert_basic_fields_exist @queue

    resp = @queue.delete!
    assert_response resp, 'msg'
    assert_equal @qname, @queue.name
    assert_equal @client.project_id, @queue.project_id

    assert_raises(Rest::HttpError) { @queue.delete! }
  end

  def test_add_subscribers
    sub1, sub2, sub3 = make_subscribers(3)

    resp = @queue.create!(push: {subscribers: [sub1]})
    assert_response resp, 'queue'
    assert_subscribers_equal [sub1], @queue.subscribers

    resp = @queue.add_subscribers([sub2])
    assert_response resp, 'msg'
    @queue.get_info!
    assert_subscribers_equal [sub1, sub2], @queue.subscribers

    resp = @queue.add_subscribers([sub3], true)
    assert_response resp, 'msg'
    assert_subscribers_equal [sub1, sub2, sub3], @queue.subscribers
  end

  def test_remove_subscribers
    sub1, sub2, sub3 = make_subscribers(3)

    resp = @queue.create!(push: {subscribers: [sub1, sub2, sub3]})
    assert_response resp, 'queue'
    assert_subscribers_equal [sub1, sub2, sub3], @queue.subscribers

    resp = @queue.remove_subscribers([sub1])
    assert_response resp, 'msg'
    @queue.get_info!
    assert_subscribers_equal [sub2, sub3], @queue.subscribers

    resp = @queue.remove_subscribers([sub2], true)
    assert_response resp, 'msg'
    assert_subscribers_equal [sub3], @queue.subscribers
  end

  def test_replace_subscribers
    sub1, sub2, sub3 = make_subscribers(3)

    resp = @queue.create!(push: {subscribers: [sub1, sub2]})
    assert_response resp, 'queue'
    assert_subscribers_equal [sub1, sub2], @queue.subscribers

    resp = @queue.replace_subscribers([sub1, sub3])
    assert_response resp, 'msg'
    @queue.get_info!
    assert_subscribers_equal [sub1, sub3], @queue.subscribers

    resp = @queue.replace_subscribers([sub2], true)
    assert_response resp, 'msg'
    assert_subscribers_equal [sub2], @queue.subscribers
  end

  # FIXME: when alerts API of IronMQ v3 will be completed,
  #        remove `skip`s and test the tests ( ;
  def test_add_alerts
    skip
    alerts = make_alerts(3)

    resp = @queue.create!
    assert_response resp, 'queue'

    resp = @queue.add_alerts(alerts)
    assert_response resp, 'msg'
    assert_nil @queue.alerts
    @queue.get_info!
    assert_alerts_equal alerts, @queue.alerts

    alrt = make_alerts(1)
    resp = @queue.add_alerts!(alrt)
    assert_response resp, 'msg'
    assert_alerts_equal alerts.concat(alrt), @queue.alerts
  end

  def test_remove_alerts
    skip
    alerts = make_alerts(3)

    resp = @queue.create!
    assert_response resp, 'queue'
    resp = @queue.add_alerts!(alerts)
    assert_response resp, 'msg'
    assert_alerts_equal alerts, @queue.alerts

    rm, *keep = alerts
    resp = @queue.remove_alerts([rm])
    assert_response resp, 'msg'
    assert_alerts_equal alerts, @queue.alerts
    @queue.get_info!
    assert_alerts_equal keep, @queue.alerts

    rm, *keep = keep
    resp = @queue.remove_alerts!([rm])
    assert_response resp, 'msg'
    assert_alerts_equal keep, @queue.alerts
  end

  def test_replace_alerts
    skip
    alerts1 = make_alerts(3)
    alerts2 = make_alerts(2)

    resp = @queue.create!
    assert_response resp, 'queue'
    resp = @queue.add_alerts!(alerts1)
    assert_response resp, 'msg'
    assert_alerts_equal alerts1, @queue.alerts

    resp = @queue.replace_alerts(alerts2)
    assert_response resp, 'msg'
    assert_alerts_equal alerts1, @queue.alerts
    @queue.get_info!
    assert_alerts_equal alerts2, @queue.alerts

    resp = @queue.replace_alerts!(alerts1)
    assert_response resp, 'msg'
    assert_alerts_equal alerts1, @queue.alerts
  end

  def test_post_messages_bodies
    bodies = make_messages_bodies(2)

    msgs = @queue.post_messages(bodies, instantiate: true)
    msgs.zip(bodies).each do |msg, body|
      assert_instance_of IronMQ::Message, msg,
                         'message must be instance of IronMQ::Message class'
      assert_equal body, msg.body, 'message must have the same body'
    end

    resp = @queue.post_messages(bodies, delay: 1)
    assert_response resp, 'ids'
    assert_equal bodies.size, resp['ids'].size

    msgs = @queue.post_messages(bodies, delay: 5, instantiate: true)
    msgs.zip(bodies).each do |msg, body|
      assert_instance_of IronMQ::Message, msg,
                         'message must be instance of IronMQ::Message class'
      assert_equal body, msg.body, 'message must have the same body'
    end

    body = bodies.first
    resp = @queue.post_message(body)
    assert_response resp, 'ids'
    assert_equal 1, resp['ids'].size

    msg = @queue.post_message(body, delay: 3, instantiate: true)
    assert_instance_of IronMQ::Message, msg
    assert_equal body, msg.body
  end

  def test_post_messages_hashes
    hashes = make_messages_hashes(2)

    msgs = @queue.post_messages(hashes, instantiate: true)
    msgs.zip(hashes).each do |msg, h|
      assert_instance_of IronMQ::Message, msg,
                         'message must be instance of IronMQ::Message class'
      assert_equal h[:body], msg.body, 'message must have the same body'
    end
    
    resp = @queue.post_messages(hashes, delay: 3)
    assert_response resp, 'ids'
    assert_equal hashes.size, resp['ids'].size

    msgs = @queue.post_messages(hashes, instantiate: true, delay: 1)
    msgs.zip(hashes).each do |msg, h|
      assert_instance_of IronMQ::Message, msg,
                         'message must be instance of IronMQ::Message class'
      assert_equal h[:body], msg.body, 'message must have the same body'
    end
  end

  def test_reserve_messages
    bodies = make_messages_bodies(2)

    @queue.post_messages(bodies)
    bodies.each do |body|
      msg = @queue.reserve_message
      assert_instance_of IronMQ::Message, msg
      refute_nil msg.id
      refute_empty msg.id
      refute_nil msg.reservation_id
      refute_empty msg.reservation_id
      assert_equal body, msg.body, 'queue is not FIFO...'
    end

    remake_default_queue

    hashes = make_messages_hashes(3)
    @queue.post_messages(hashes)
    msgs = @queue.reserve_messages(n: hashes.size)
    assert_equal hashes.size, msgs.size
    msgs.zip(hashes).each do |msg, h|
      assert_instance_of IronMQ::Message, msg
      refute_nil msg.id
      refute_empty msg.id
      refute_nil msg.reservation_id
      refute_empty msg.reservation_id
      assert_equal h[:body], msg.body, 'queue is not FIFO...'
    end
  end

  def test_get_message_by_id
    body = 'my message'
    resp = @queue.post_message(body)
    assert_response resp, 'ids'
    assert_equal 1, resp['ids'].size

    id = resp['ids'].first
    msg = @queue.get_message_by_id(id)
    assert_instance_of IronMQ::Message, msg
    refute_nil msg.id
    refute_empty msg.id
    assert_equal body, msg.body
  end

  def test_peek_messages
    bodies = make_messages_bodies(3)
    resp = @queue.post_messages(bodies)
    assert_response resp, 'ids'
    ids = resp['ids']
    assert_equal bodies.size, ids.size

    msgs = @queue.peek_messages
    assert_equal 1, msgs.size
    assert_instance_of IronMQ::Message, msgs.first
    assert_equal ids[0], msgs.first.id

    msgs = @queue.peek_messages(n: bodies.size)
    assert_equal bodies.size, msgs.size
    msgs.zip(bodies, ids).each do |msg, body, id|
      assert_instance_of IronMQ::Message, msg
      assert_equal body, msg.body, 'queue is not FIFO...'
      assert_equal id, msg.id, 'queue is not FIFO...'
    end
  end

  def test_delete_messages
    bodies = make_messages_bodies(5)
    resp = @queue.post_messages(bodies)
    assert_response resp, 'ids'
    ids = resp['ids']
    assert_equal bodies.size, ids.size

    msg = @queue.reserve_message
    assert_instance_of IronMQ::Message, msg
    assert_equal ids[0], msg.id
    assert_equal bodies[0], msg.body
    resp = @queue.delete_message(msg)
    assert_response resp, 'msg'
    assert_raises(Rest::HttpError) do
      @queue.get_message_by_id(ids[0])
    end

    resp = @queue.delete_message(ids[1])
    assert_response resp, 'msg'
    assert_raises(Rest::HttpError) do
      @queue.get_message_by_id(ids[1])
    end

    msgs = @queue.reserve_messages(n: 3)
    msgs_ids = msgs.map(&:ids)
    resp = @queue.delete_messages(msgs_ids)
    assert_response resp, 'msg'
    ids.slice(2..4).each do |id|
      assert_raises(Rest::HttpError) do
        @queue.get_message_by_id(id)
      end
    end

    msg = @queue.reserve_message
    assert_nil msg
  end

  def test_delete_all_messages
    bodies = make_messages_bodies(3)
    resp = @queue.post_messages(bodies)
    assert_response resp, 'ids'

    resp = @queue.delete_all_messages
    assert_response resp, 'msg'

    msg = @queue.reserve_message
    assert_nil msg
  end
end
