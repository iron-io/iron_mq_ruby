gem 'minitest'
require 'minitest/autorun'

require 'helpers'

class TestMessage < Minitest::Test
  include Helpers

  def setup
    @client = IronMQ::Client.new
    @qname = 'brave-new-v3-message'
    @queue = @client.queue(@qname)
  end

  def teardown
    delete_queue(@client, @qname)
  end

  def test_new
    id = '123'
    m = IronMQ::Message.new(@client, @qname, id: id)
    assert_instance_of IronMQ::Message, m
    assert_equal id, m.id

    body = 'message body'
    m = IronMQ::Message.new(@client, @qname, id: id, body: body)
    assert_instance_of IronMQ::Message, m
    assert_equal id, m.id
    assert_equal body, m.body

    assert_raises(ArgumentError) do
      IronMQ::Message.new(@client, nil, id: id)
    end

    assert_raises(ArgumentError) do
      IronMQ::Message.new(@client, '', id: id)
    end

    assert_raises(ArgumentError) do
      IronMQ::Message.new(@client, @qname, body: body)
    end
  end

  def test_compare_messages
    message = IronMQ::Message.new(@client, @qname, id: '6161270473550831393')
    same_message = IronMQ::Message.new(@client, @qname, id: '6161270473550831393')
    not_same_message = IronMQ::Message.new(@client, @qname, id: '6161270473550831394')
    nil_message = nil

    assert message == same_message
    assert message != not_same_message
    assert message != nil_message
  end

  def test_touch
    bodies = make_messages_bodies(2)
    resp = @queue.post_messages(bodies)
    assert_response resp, 'ids'
    ids = resp['ids']
    assert_equal bodies.size, ids.size

    msgs = @queue.reserve_messages(n: bodies.size)
    assert_equal bodies.size, msgs.size
    msgs.zip(ids).each do |msg, id|
      assert_equal id, msg.id
      refute_nil msg.reservation_id

      mhash = msg.to_h
      resp = msg.touch!
      assert_response resp, 'msg', 'reservation_id'
      assert_equal mhash[:id], msg.id
      refute_equal mhash[:reservation_id], msg.reservation_id
    end
  end

  def test_release
    body = 'message body'
    resp = @queue.post_message(body)
    assert_response resp, 'ids'
    assert_equal 1, resp['ids'].size
    id = resp['ids'].first

    msg = @queue.reserve_message
    assert_instance_of IronMQ::Message, msg
    assert_equal id, msg.id
    assert_equal body, msg.body

    no_msg = @queue.reserve_message
    assert_nil no_msg

    resp = msg.release!
    refute_nil resp['msg']

    rsrv_msg = @queue.reserve_message
    assert_instance_of IronMQ::Message, rsrv_msg
    assert_equal msg.id, rsrv_msg.id
    assert_equal msg.body, rsrv_msg.body
    refute_equal msg.reservation_id, rsrv_msg.reservation_id
  end

  def test_get
    body = 'message body'
    msg = @queue.post_message(body, instantiate: true)
    assert_instance_of IronMQ::Message, msg
    refute_nil msg.id
    refute_empty msg.body
    assert_equal body, msg.body

    resp = msg.get!
    assert_response resp, 'message'
    assert_nil msg.reservation_id
    assert_equal 0, msg.reserved_count
  end

  def test_delete
    body = 'message body'
    resp = @queue.post_message(body)
    assert_response resp, 'ids'
    assert_equal 1, resp['ids'].size
    id = resp['ids'].first

    msg = @queue.reserve_message
    assert_instance_of IronMQ::Message, msg
    assert_equal id, msg.id
    assert_equal body, msg.body

    resp = msg.delete!
    assert_response resp, 'msg'
    assert_raises(Rest::HttpError) { msg.delete! }

    msg = @queue.post_message(body, instantiate: true)
    assert_instance_of IronMQ::Message, msg
    assert_equal body, msg.body

    resp = msg.delete!
    assert_response resp, 'msg'
    assert_raises(Rest::HttpError) { msg.delete! }
  end

  def test_get_push_statuses
    subs = [{name: 'zen',
             url: 'http://i-hope-nobody-register-this-domain.com/push'}]
    resp = @queue.create!(push: {subscribers: subs})
    assert_response resp, 'queue'
    assert_subscribers_equal subs, @queue.subscribers

    msg = @queue.post_message('push message', instantiate: true)
    assert_instance_of IronMQ::Message, msg
    # NOTE: sleep grants pusher some time to process the message.
    #       If one of assertions fails, make sure, that higher wait time
    #       does not resolve the issue, before try to fix test itself.
    #
    # To run only this test do the following in terminal:
    #   $ rake test TEST=test/iron_mq/test_message.rb \
    #               TESTOPTS="--name=test_get_push_statuses -v"
    sleep 5
    resp = msg.get_push_statuses
    assert_response resp, 'subscribers'
    assert_equal subs.size, resp['subscribers'].size
    assert_equal subs.first[:name], resp['subscribers'].first['subscriber_name']
    assert_nil msg.push_statuses

    msg.get_push_statuses!
    refute_nil msg.push_statuses
    assert_equal subs.size, msg.push_statuses.size
    assert_equal subs.first[:name], msg.push_statuses.first[:subscriber_name]
  end
end
