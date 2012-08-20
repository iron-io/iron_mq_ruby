# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

#$abt_config = {:hello=>'abt_config_ya'}

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

    queues = @client.queues.list
    p queues

    clear_queue()

  end

  def test_performance_post_100_messages
    @client.queue_name = 'test_basics_6'
    # slower to rackspace since this is running on aws
    timeout = @client.host.include?('rackspace') ? 40 : 12
    assert_performance timeout do
      100.times do
        @client.messages.post("hello world!")
      end
    end
  end


  def test_basics
    queue_name = 'test_basics_6'
    @client.queue_name = queue_name
    clear_queue

    res = @client.messages.post("hello world!")
    p res
    assert res["id"]
    assert res.id
    assert res.msg

    queue = @client.queues.get(:name => @client.queue_name)
    p queue
    assert queue.reload.size == 1, "Size was not 1 after insert, it was: #{queue.size}"
    res = @client.messages.get()
    p res
    assert res["id"]
    assert res.id

    res = @client.messages.delete(res["id"])
    p res
    puts "shouldn't be any more"
    res = @client.messages.get()
    p res
    assert res.nil?

    queue = @client.queues.get(:name => @client.queue_name)
    assert queue.size == 0

    res = @client.messages.post("hello world 2!")
    p res

    msg = @client.messages.get()
    p msg
    assert msg

    res = msg.delete
    p res

    puts "shouldn't be any more"
    res = @client.messages.get()
    p res
    assert res.nil?


    # new style of referencing queue
    queue = @client.queue(queue_name)
    v = "hello big world"
    res = queue.post(v)
    p res
    assert res.msg

    res = queue.get()
    p res
    assert res["id"]
    assert res.id
    assert res.body == v

    res = queue.delete(res.id)
    p res
    puts "shouldn't be any more"
    res = queue.get()
    p res
    assert res.nil?

    # test delete by item
    res = queue.post(v)
    p res
    assert res.msg

    res = queue.get()
    p res
    assert res.body
    res = res.delete
    p res
    puts "shouldn't be any more"
    res = queue.get()
    p res
    assert res.nil?

  end

  # TODO: pass :timeout in post/get messages and test those
  def test_timeout
    @client.queue_name = "test_timeout_6"
    clear_queue

    res = @client.messages.post("hello world timeout!")
    p res

    msg = @client.messages.get()
    p msg
    assert msg

    msg4 = @client.messages.get()
    p msg4
    assert msg4.nil?

    puts 'sleeping 45 seconds...'
    sleep 45

    msg3 = @client.messages.get()
    p msg3
    assert msg3.nil?

    puts 'sleeping another 45 seconds...'
    sleep 45

    msg2 = @client.messages.get()
    assert msg2
    assert msg.id == msg2.id

    msg2.delete

    # now try explicit timeout
    res = @client.messages.post("hello world timeout2!", :timeout => 10)
    p res
    msg = @client.messages.get()
    p msg
    assert msg
    msg4 = @client.messages.get()
    p msg4
    assert msg4.nil?
    puts 'sleeping 15 seconds...'
    sleep 15
    msg2 = @client.messages.get()
    assert msg2
    assert msg.id == msg2.id

  end

  def test_queues
    puts 'test_queues'

    assert_raise Rest::HttpError do
      # should raise a 404
      q = @client.queues.get(:name => "some_queue_that_does_not_exist")
    end

    res = @client.queues.list()
    puts "res.size: " + res.size.to_s
    res.each do |q|
      puts "queue_name: " + q.name
      puts "queue size: " + q.size.to_s
      assert q.size >= 0
    end
    assert res.size > 0

    res = @client.queues.list(:page => 15)
    puts "res.size 2: " + res.size.to_s
    res.each do |q|
      p q.name
    end
    assert res.size == 0


    queue = @client.queue("test_basics_6")
    assert queue.name
    assert queue.size


  end

  def test_delay
    puts 'test_delay'
    @client.queue_name = "test_delay_6"
    clear_queue
    msgTxt = "testMessage-"+Time.now.to_s
    puts msgTxt
    @client.messages.post(msgTxt, {:delay => 10})
    msg = @client.messages.get
    p msg
    assert msg.nil?
    sleep 10
    msg = @client.messages.get
    p msg
    assert msg
  end

  def test_batch
    puts 'test_batch'
    @client.queue_name = "test_batch_6"
    clear_queue

    x = []
    10.times do |i|
      x << {:body => "body #{i}"}
    end
    resp = @client.messages.post(x)
    assert resp["ids"]
    assert resp["ids"].is_a?(Array)
    assert resp["ids"].size == 10

    msg = @client.messages.get()
    assert msg
    assert msg['id']
    msg.delete

    msgs = @client.messages.get(:n => 10)
    assert msgs.is_a?(Array)
    assert msgs.size == 9, "size should be 9, but it's #{msgs.size}"
    assert msgs[0]["id"]

    msgs.each do |m|
      m.delete
    end
  end

  def test_release
    puts 'test_release'
    @client.queue_name = "test_release_6"
    clear_queue
    msgTxt = "testMessage-"+Time.now.to_s
    puts msgTxt
    msg_id = @client.messages.post(msgTxt, {:timeout => 60*5}).id
    puts "msg_id: #{msg_id}"
    msg = @client.messages.get
    p msg
    assert msg.id == msg_id
    # Ok, so should have received same message, now let's release it quicker than the original timeout

    # but first, ensure the next get is nil
    msg = @client.messages.get
    p msg
    assert msg.nil?

    # now release it instantly
    @client.messages.release(msg_id)
    msg = @client.messages.get
    p msg
    assert msg
    assert msg.id == msg_id

    # ok, so should be reserved again
    msgr = @client.messages.get
    p msgr
    assert msgr.nil?

    # let's release it in 10 seconds
    @client.messages.release(msg_id, :delay => 10)
    msg = @client.messages.get
    p msg
    assert msg.nil?

    sleep 11

    msg = @client.messages.get
    p msg
    assert msg

    msg.release(:delay => 5)
    msg = @client.messages.get
    p msg
    assert msg.nil?

    sleep 6

    msg = @client.messages.get
    p msg
    assert msg

  end

  def test_clear

    q = @client.queue("clearer_6")

    clear_queue(q.name)

    val = "hi mr clean"
    q.post(val)
    assert q.size == 1

    q.clear
    msg = q.get
    assert msg.nil?

    q.reload

    assert q.reload.size == 0, "Size was not zero after clear, it was: #{q.size}"

  end



  def test_poll
    queue = @client.queue("test_poll_6")
    queue.clear

    v = "hello world"
    5.times do
      queue.post(v)
    end

    i = 0
    queue.poll(:break_if_nil=>true) do |msg|
      assert msg.body.include?("hello")
      i += 1
    end
    assert i == 5, "Polled #{i} messages, but there should have only been five messages in queue. "

    assert queue.reload.size == 0, "Size was not zero after poll, it was: #{queue.size}"

  end
  #
  #def test_delete
  #  queue = @client.queue("test_delete")
  #  queue.post("hi")
  #  queue.reload
  #  old_id = queue.id
  #  queue.delete_queue
  #
  #  puts "sleeping for a bit to let queue delete..."
  #  sleep 60
  #
  #  queue.post("hi2")
  #  p queue
  #  queue.reload
  #  assert queue.id != old_id, "old_id: #{old_id} is equal to new id: #{queue.id}"
  #  assert queue.size == 1
  #  queue.get("").body == "hi2"
  #
  #end


end

