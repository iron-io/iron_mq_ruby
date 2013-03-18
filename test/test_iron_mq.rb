require 'test/unit'
require 'yaml'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

class IronMQTests < TestBase
  def setup
    super
    @skip = @host.include? 'rackspace'
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


  def test_basics
    queue_name = 'test_basics_7'
    clear_queue(queue_name)

    # NOTE: Kept for backward compatibility checking
    queue = @client.queues.get(:name => queue_name)
    # p queue
    res = queue.post("hello world!")
    # p res

    assert res["id"]
    assert res.id
    assert res.msg

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

    assert_equal 0, queue.size

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


  def test_queues_list
    queue_name = 'test_queues_list'
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
    queue_name = "test_timeout_6"
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

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      new_msg = queue.get
      # p new_msg
      next if new_msg.nil?

      assert_equal new_msg.id, msg.id

      new_msg.delete
      break
    end
    assert_not_equal tries, 0

    # now try explicit timeout
    res = queue.post("hello world timeout2!", :timeout => 30)
    # p res
    msg = queue.get
    # p msg
    assert msg
    assert_equal msg.raw['timeout'], 30

    msg_nil = queue.get
    # p msg_nil
    assert_nil msg_nil

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      new_msg = queue.get
      next if new_msg.nil?

      assert_equal new_msg.id, msg.id

      new_msg.delete
      break
    end
    assert_not_equal tries, 0

    # timeout on get
    res = queue.post("hello world timeout3!")
    msg = queue.get(:timeout => 30)
    assert msg
    assert_equal msg.raw['timeout'], 30

    msg_nil = queue.get
    # p msg_nil
    assert_nil msg_nil

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      new_msg = queue.get
      next if new_msg.nil?

      assert_equal new_msg.id, msg.id

      new_msg.delete
      break
    end
    assert_not_equal tries, 0

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_queues
    puts 'test_queues'

    # Now client library is not provide plain call to API
    # But creates Queue object instead
    # also added `#new?` method to check is queue exist
    #
    #assert_raise Rest::HttpError do
    #  # should raise a 404
    #  q = @client.queues.get(:name => "some_queue_that_does_not_exist")
    #end
    queue = @client.queues.get(:name => "some_queue_that_does_not_exist")
    assert queue.new? == true

    res = @client.queues.list
    # puts "res.size: #{res.size}"
    res.each do |q|
      # puts "queue_name: " + q.name
      # puts "queue size: " + q.size.to_s
      assert q.size >= 0
    end
    assert res.size > 0

    res = @client.queues.list(:page => 15)
    # puts "res.size 2: #{res.size}"
    # res.each do |q| { p q.name }

    assert_equal 0, res.size
  end

  def test_delay
    puts 'test_delay'

    queue_name = "test_delay_6"
    clear_queue(queue_name)

    msgTxt = "testMessage-"+Time.now.to_s
    # puts msgTxt
    queue = @client.queue(queue_name)
    queue.post(msgTxt, {:delay => 5})
    msg = queue.get
    # p msg
    assert_nil msg

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      msg = queue.get
      # p msg
      next if msg.nil?

      assert_equal msg.body, msgTxt

      break
    end
    assert_not_equal tries, 0

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_batch
    puts 'test_batch'

    queue_name = "test_batch_6"
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
    msg.delete

    msgs = queue.get(:n => 10)
    assert msgs.is_a?(Array)
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

    queue_name = "test_msg_peek"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post([ {:body => "first message"},
                 {:body => "second message"},
                 {:body => "third message"} ])

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
    puts "test_message_touch"

    queue_name = "test_msg_touch"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post([
                {:body => "first message"},
                {:body => "second message"},
                {:body => "third message"}
               ],
               {:timeout => 30}) # minimum timeout

    # get message
    msg = queue.get
    assert_not_nil msg
    assert_equal "first message", msg.body, "message body must be 'first message', but it's '#{msg.body}'"    

    sleep 15 # timeout is not passed

    msgs = queue.peek(:n => 3) # all messages from queue
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 2, msgs.size, "API must return only 2 messages"
    msgs.each { |m| assert_not_equal msg.id, m.id, "returned message which must be reserved" }

    sleep 20 # ensure timeout is passed

    # message must return to the queue
    msgs = queue.peek(:n => 3)
    assert_equal Array, msgs.class, "waiting for Array, but got #{msgs.class}"
    assert_equal 3, msgs.size, "API must return 3 messages"
    assert_equal msg.id, msgs[2].id, "released message must be at the end of the queue"

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

    msgTxt = "testMessage-"+Time.now.to_s
    # puts msgTxt

    queue = @client.queue(queue_name)

    msg_id = queue.post(msgTxt, {:timeout => 60*5}).id
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

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      msg = queue.get
      next if msg.nil?

      #p msg
      assert_equal msg.id, msg_id

      break
    end
    assert_not_equal tries, 0

    msg.release(:delay => 5)
    msg = queue.get
    # p msg
    assert_nil msg

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      sleep 1

      msg = queue.get
      next if msg.nil?

      # p msg
      assert_equal msg.id, msg_id

      break
    end
    assert_not_equal tries, 0

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_clear
    puts "test_clear"

    queue = @client.queue("test_clear_7")
    clear_queue(queue.name)

    val = "hi mr clean"
    queue.post(val)

    sleep 0.5 # make sure the counter has time to update
    assert_equal 1, queue.size

    queue.clear

    msg = queue.get
    assert_nil msg

    assert_equal 0, queue.size

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

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      break if 0 == queue.size
      sleep 0.5
    end
    assert_not_equal tries, 0

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
    q_info = queue.info
    assert_not_equal old_id, q_info.id, "old queue ID (#{old_id}) must not be equal to new ID (#{q_info.id})"
    assert_equal 1, q_info.size, "queue size must be 1, but got #{q_info.size}"

    msg = queue.get
    assert_equal "hi2", msg.body, "message body must be 'hi2', but got '#{msg.body}'"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_webhooks
    return if @skip
    puts "skip webhooks: #{@skip}"
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

end

