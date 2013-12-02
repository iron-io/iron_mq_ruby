require 'test/unit'
require 'yaml'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

class IronMQTests < TestBase
  def setup
    super
    LOG.info "@host: #{@host}"

    queues = @client.queues.list
    # p queues
  end

  def test_performance_post_100_messages
    queue = @client.queue('test_perf_100')
    # slower to rackspace since this is running on aws
    timeout = @host.include?('rackspace') ? 40 : 12

    assert_performance(timeout) do
      100.times do
        queue.post("hello world!")
      end

      # delete queue on test complete
      resp = queue.delete_queue
      assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
    end
  end

  def test_get
    queue_name = "some_queue_abcj9u23"
    queue = @client.queue(queue_name)
    msg = queue.get
    v = "hello big world"
    queue.post(v)
    msg = queue.get
    msg.delete
    msg = queue.get

  end

  def test_basics
    queue_name = 'test_basics_71'
    clear_queue(queue_name)

    # NOTE: Kept for backward compatibility checking
    queue = @client.queues.get(:name => queue_name)
    # p queue
    res = queue.post("hello world!")
    # p res

    assert res["id"]
    assert res.id
    assert res.msg
    sleep 0.3
    assert_equal 1, queue.size

    message = queue.get
    # p res
    assert res["id"]
    assert res.id

    res = queue.delete(res["id"])
    # p res
    puts "shouldn't be any more"
    res = queue.get
    # p res
    assert_nil res

    sleep 0.3
    assert_equal 0, queue.reload.size

    res = queue.post("hello world 2!")
    # p res

    msg = queue.get
    # p msg
    assert msg

    res = msg.delete
    #p res

    puts "shouldn't be any more"
    res = queue.get
    # p res
    assert_nil res

    # new style of referencing queue
    queue = @client.queue(queue_name)
    v = "hello big world"
    res = queue.post(v)
    # p res
    assert res.msg

    res = queue.get
    # p res
    assert res["id"]
    assert res.id
    assert_equal v, res.body

    res = queue.delete(res.id)
    # p res
    puts "shouldn't be any more"
    res = queue.get
    # p res
    assert_nil res

    # test delete by item
    res = queue.post(v)
    # p res
    assert res.msg

    res = queue.get
    # p res
    assert res.body

    res = res.delete
    # p res
    puts "shouldn't be any more"
    res = queue.get
    # p res
    assert_nil res

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_multi_delete
    queue_name = 'test_multi_delete_41'
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    ids = []
    10.times do |i|
      msg = queue.post("hello #{i}")
      ids << msg.id
    end
    sleep 0.5
    assert_equal 10, queue.reload.size

    queue.delete_messages(ids)
    sleep 1
    assert_equal 0, queue.reload.size
    queue.delete_queue

  end

  def test_queues_list
    queue_name = 'test_queues_list_1'
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    res = queue.post("hello world!")
    # p res

    res = @client.queues.list
    assert res.size > 0, "project must contain at least one queue"

    res.each do |q|
      # puts "#{q.name} and #{queue_name}"
      if q.name == queue_name
        assert_equal q.size, 1
      end
    end

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  # TODO: pass :timeout in post/get messages and test those
  def test_timeout
    queue_name = "test_timeout_71"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)

    res = queue.post("hello world timeout!")
    # p res

    msg = queue.get
    # p msg
    assert msg

    msg_nil = queue.get
    # p msg_nil
    assert_nil msg_nil

    sleep 61 # should be 1 minute timeout by default
    new_msg = queue.get
    assert_not_nil new_msg
    assert_equal new_msg.id, msg.id
    new_msg.delete

    # now try explicit timeout
    res = queue.post("hello world timeout2!", :timeout => 30)
    # p res
    msg = queue.get
    # p msg
    assert msg
    assert_equal 30, msg.timeout

    msg_nil = queue.get
    # p msg_nil
    assert_nil msg_nil

    sleep 31
    new_msg = queue.get
    assert_not_nil new_msg
    assert_equal new_msg.id, msg.id
    new_msg.delete

    # timeout on get
    res = queue.post("hello world timeout3!")
    msg = queue.get(:timeout => 30)
#    puts "MESSAGE IS #{msg.inspect}"
    assert msg
    assert_equal msg.timeout, 30

    msg_nil = queue.get
    # p msg_nil
    assert_nil msg_nil

    sleep 31
    new_msg = queue.get
    assert_not_nil new_msg
    assert_equal new_msg.id, msg.id
    new_msg.delete

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_queues
    puts 'test_queues'

    qname = "some_queue_that_does_not_exist_1"
    queue = @client.queue(qname)
    # delete it before the test
    queue.delete_queue

    assert_raise Rest::HttpError do
      # should raise a 404
      m = queue.size
    end

    # create at least one queue
    queue.post('create queue message')
    # queue should exist now
    m = queue.get
    assert_not_nil m

    res = @client.queues.list
    # puts "res.size: #{res.size}"
    res.each do |q|
      # puts "queue_name: " + q.name
      # puts "queue size: " + q.size.to_s
      assert q.size >= 0
    end
    assert res.size > 0

    res = @client.queues.list(:page => 50)
    # puts "res.size 2: #{res.size}"
    # res.each do |q| { p q.name }

    assert_equal 0, res.size

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_delay
    puts 'test_delay'

    queue_name = "test_delay_61"
    clear_queue(queue_name)

    msgTxt = "testMessage-"+Time.now.to_s
    # puts msgTxt
    queue = @client.queue(queue_name)
    msg_id = queue.post(msgTxt, {:delay => 5}).id
    msg = queue.get
    # p msg
    assert_nil msg

    sleep 6
    new_msg = queue.get
    assert_not_nil new_msg
    assert_equal msg_id, new_msg.id
    new_msg.delete

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_batch
    puts 'test_batch'

    queue_name = "test_batch_61"
    clear_queue(queue_name)

    x = []
    10.times do |i|
      x << {:body => "body #{i}"}
    end

    queue = @client.queue(queue_name)

    resp = queue.post(x)
    assert resp["ids"]
    assert resp["ids"].is_a?(Array)
    assert_equal 10, resp["ids"].size

    msg = queue.get
    assert msg
    assert msg['id']
    puts "Deleting message #{msg.id}"
    msg.delete
    sleep 2

    msgs = queue.get(:n => 10)
    assert msgs.is_a?(Array)
    msgs.each do |m|
      puts m.id
      assert_not_equal msg.id, m.id
    end
    assert msgs.size == 9, "size should be 9, but it's #{msgs.size}"
    assert msgs[0]["id"]

    msgs.each do |m|
      resp = m.delete
      assert_equal 200, resp.code, "API must delete message and response with HTTP 200 status, but returned HTTP #{resp.code}"
    end

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_peek
    puts "test_message_peek"

    queue_name = "test_msg_peek_1"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post("zero message")
    msg = queue.get
    msg.delete

    msg = queue.peek
    assert_nil msg

    queue.post("first message")
    sleep 1
    queue.post("second message")
    sleep 1
    queue.post("third message")

    msg = queue.peek
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"

    msg = queue.peek
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"

    msgs = queue.peek(:n => 2)
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 2, msgs.size, "must received 2 messages, but received #{msgs.size}"

    msg = queue.peek
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"

    msgs = queue.peek(:n => 7)
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 3, msgs.size, "must received 3 messages, but received #{msgs.size}"

    msg = queue.get
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"

    resp = msg.delete
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"

    msg = queue.peek
    assert_not_nil msg
    assert_equal "second message", msg.body, "message body must be 'second message', but it's '#{msg.body}'"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_touch
    puts "in test_touch"

    queue_name = "test_msg_touch_3"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post("first message", :timeout => 30)
    queue.post("second message", :timeout => 30)
    queue.post("third message", :timeout => 30)


    # get message
    msg = queue.get
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"

    sleep 15 # timeout is not passed

    msgs = queue.peek(:n => 3) # all messages from queue
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 2, msgs.size, "API must return only 2 messages"
    msgs.each do |m|
      assert_not_equal msg.id, m.id, "returned a message which must be reserved"
    end

    sleep 20 # ensure timeout is passed

    # message must return to the queue
    msgs = queue.peek(:n => 3)
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 3, msgs.size, "API must return 3 messages"

    msg = queue.get
    assert_not_nil msg
    assert_equal "second message", msg.body, "message body must be 'second message', but it's '#{msg.body}'"

    sleep 15 # timeout is not passed

    msgs = queue.peek(:n => 3) # must return another message
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 2, msgs.size, "API must return only 2 messages"
    msgs.each { |m| assert_not_equal msg.id, m.id, "returned message which must be reserved" }

    resp = msg.touch # more 30 seconds timeout
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"

    sleep 20 # new timeout is not passed, but previous is (15 + 20 vs 30 + 30 seconds)

    msgs = queue.peek(:n => 3) # must return the same as for msg2
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 2, msgs.size, "API must return only 2 messages"
    msgs.each { |m| assert_not_equal msg.id, m.id, "returned message which must be reserved" }

    sleep 15 # ensure timeout passed

    # message must be returned to the end of the queue
    msgs = queue.peek(:n => 3)
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 3, msgs.size, "API must return 3 messages"
    assert_equal msg.id, msgs[2].id, "released message must be at the end of the queue"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_release
    puts 'test_release'

    queue_name = "test_release_6"
    clear_queue(queue_name)

    msg_txt = "testMessage-"+Time.now.to_s
    # puts msgTxt

    queue = @client.queue(queue_name)

    msg_id = queue.post(msg_txt, {:timeout => 60*5}).id
    # puts "msg_id: #{msg_id}"
    message = queue.get
    # p msg
    assert_equal msg_id, message.id
    # Ok, so should have received same message, now let's release it quicker than the original timeout

    # but first, ensure the next get is nil
    msg = queue.get
    # p msg
    assert_nil msg

    # now release it instantly
    message.release
    msg = queue.get
    # p msg
    assert msg
    assert_equal msg_id, msg.id

    # ok, so should be reserved again
    msgr = queue.get
    # p msgr
    assert_nil msgr

    # let's release it in 10 seconds
    msg.release(:delay => 10)
    msgr = queue.get
    # p msg
    assert_nil msgr

    sleep 11
    msg = queue.get
    assert_not_nil msg
    assert_equal msg_id, msg.id

    msg.release(:delay => 5)
    msg = queue.get
    # p msg
    assert_nil msg

    sleep 6
    msg = queue.get
    assert_not_nil msg
    assert_equal msg_id, msg.id

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_clear
    puts "test_clear"

    queue = @client.queue("test_clear_9")
    clear_queue(queue.name)

    val = "hi mr clean"
    queue.post(val)

    sleep 0.5 # make sure the counter has time to update
    assert_equal 1, queue.reload.size

    queue.clear

    msg = queue.get
    assert_nil msg

    sleep 0.5

    assert_equal 0, queue.reload.size

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_poll
    queue_name = "test_poll_6"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)

    v = "hello world"
    5.times { queue.post(v) }

    i = 0
    queue.poll(:break_if_nil => true) do |msg|
      assert msg.body.include?("hello")
      i += 1
    end

    assert_equal 5, i

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_queue_delete
    queue = @client.queue("test_delete")
    queue.post("hi")
    old_id = queue.id
    queue.delete_queue

    LOG.info "sleeping for a bit to let queue delete..."
    sleep 60

    queue.post("hi2")
    # p queue
    assert_not_equal old_id, queue.id, "old queue ID (#{old_id}) must not be equal to new ID (#{queue.id})"
    assert_equal 1, queue.size, "queue size must be 1, but got #{queue.size}"

    msg = queue.get
    assert_equal "hi2", msg.body, "message body must be 'hi2', but got '#{msg.body}'"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_webhooks
    qname ="webhook_queue"
    url = "#{@client.base_url}/#{qname}/messages/webhook?oauth=#{@client.token}"
    # p url

    v = "hello webhook"

    @rest = Rest::Client.new
    resp = @rest.post(url, :body => v)
    # p resp

    queue = @client.queue(qname)
    msg = queue.get
    # p msg
    assert_equal v, msg.body

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_queue_params

    qname = "test_queue_params_1"

    clear_queue(qname)
    q = @client.queue(qname)

    q.post("message 1", :timeout => 200, :delay => 0, :expires_in => 2000)
    q.post("message 1", :timeout => 300, :delay => 0, :expires_in => 3000)

    msgs = q.get(:n => 2)

    msgs.each do |m|
      puts m.body
      puts "timeout: #{m.timeout}"
      puts "expires_in: #{m.expires_in}"
      puts "delay: #{m.delay}"
    end

  end


  def test_reserved_count
    puts "test_reserved_count"

    queue_name = "test_reserved_count"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post("zero message")
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"
    msg.release
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"
    msg.release
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"


  end

  def test_queue_set_info
    qname = "test_queue_set_info"
    clear_queue(qname)
    q = @client.queue(qname)
    q.update_queue(:push_type => 'unicast')
    assert_equal 'unicast', q.push_type
    q.update_queue(:retries => 10)
    assert_equal 'unicast', q.reload.push_type
  end

  def test_dequeue_delete
    queue_name = "test_dequeue_delete_#{Time.now.to_i}"
    clear_queue(queue_name)
    queue = @client.queue(queue_name)
    v = "hello thou shalt only see me once"
    queue.post(v)
    msg = queue.get(delete: 1, timeout: 30)
    assert_equal msg.body, "hello thou shalt only see me once"
    sleep 1
    # get the queue again
    queue = @client.queue(queue_name)
    assert_equal 0, queue.size
    sleep 31
    msg = queue.get
    assert_equal nil, msg
  end
end

