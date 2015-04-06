gem 'minitest'
require 'minitest/autorun'

require 'helpers'

require 'iron_mq/client'
require 'iron_mq/queue'

class TestClient < Minitest::Test
  include Helpers

  def setup
    @client = IronMQ::Client.new
    @qname = 'brave-new-v3-client'
  end

  def teardown
    delete_queue(@client, @qname)
  end

  def assert_queue_basics(queue)
    assert_instance_of IronMQ::Queue, queue
    assert_equal @qname, queue.name
    assert_equal @client.project_id, queue.project_id
  end

  def test_make_queue_successful
    q = @client.make_queue(@qname)
    assert_queue_basics q

    qsize = 10
    q = @client.make_queue(name: @qname, size: qsize)
    assert_queue_basics q
    assert_equal qsize, q.size
  end

  def test_make_queue_failed
    assert_raises(ArgumentError) { @client.make_queue(size: 10) }

    assert_raises(ArgumentError) { @client.make_queue(10) }

    wrong_prj_id = '>^_^<'
    assert_raises(ArgumentError) do
      @client.make_queue(name: @qname, project_id: wrong_prj_id)
    end
  end

  def test_create_queue
    q = @client.create_queue(@qname)
    assert_queue_basics q

    delete_queue(@client, @qname)

    msg_timeout = 100
    msg_expire = 123456
    q = @client.create_queue(@qname, { message_timeout: msg_timeout,
                                       message_expiration: msg_expire })
    assert_queue_basics q
    assert_equal msg_timeout, q.message_timeout
    assert_equal msg_expire, q.message_expiration

    delete_queue(@client, @qname)

    subs = make_subscribers(2)
    q = @client.create_queue(@qname, push: {subscribers: subs})
    assert_queue_basics q
    assert q.push_queue?
    assert_subscribers_equal subs, q.subscribers
  end

  def test_get_queues
    qs = 3.times.reduce([]) do |lst, n|
      qname = "#{@qname}-#{n}"
      delete_queue(@client, qname)
      lst << @client.create_queue(qname)
    end

    list_qs = @client.get_queues
    assert_equal qs.size, list_qs.size
    qs.zip(list_qs).each do |q1, q2|
      assert_equal q1.name, q2.name
      assert_equal q1.project_id, q2.project_id
    end

    qs.each { |q| delete_queue(@client, q.name) }
  end

  def test_get_queue
    q = @client.create_queue(@qname)
    assert_queue_basics q

    getq = @client.get_queue(@qname)
    assert_queue_basics getq

    assert_equal q, getq
  end

  def test_update_queue
    q = @client.create_queue(@qname)
    assert_queue_basics q

    msg_timeout = 999
    msg_expire = 54321
    updq = @client.update_queue(@qname, { message_timeout: msg_timeout,
                                          message_expiration: msg_expire })
    assert_queue_basics updq
    assert_equal msg_timeout, updq.message_timeout
    assert_equal msg_expire, updq.message_expiration
  end

  def test_delete_queue
    assert_raises(Rest::HttpError) { @client.delete_queue(@qname) }

    q = @client.create_queue(@qname)
    assert_queue_basics q

    resp = @client.delete_queue(@qname)
    assert resp.member?('msg')
  end
end
