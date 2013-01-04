gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super
    @skip = @host.include? 'rackspace'
    LOG.info "@host: #{@host}"
    queues = @client.queues.list
    p queues
    clear_queue()
  end

  def test_performance_post_100_messages
    @client.queue_name = 'test_perf_100'
    # slower to rackspace since this is running on aws
    timeout = @host.include?('rackspace') ? 40 : 12
    assert_performance timeout do
      100.times do
        @client.messages.post("hello world!")
      end
    end
  end


  def test_basics
    queue_name = 'test_basics_7'
    @client.queue_name = queue_name
    clear_queue

    res = @client.messages.post("hello world!")
    p res
    assert res["id"]
    assert res.id
    assert res.msg

    queue = @client.queues.get(:name => @client.queue_name)
    p queue
    assert_equal 1, queue.reload.size
    res = @client.messages.get()
    p res
    assert res["id"]
    assert res.id

    res = @client.messages.delete(res["id"])
    p res
    puts "shouldn't be any more"
    res = @client.messages.get()
    p res
    assert_nil res

    queue = @client.queues.get(:name => @client.queue_name)
    assert_equal 0, queue.size

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
    assert_nil res


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
    assert_equal v, res.body

    res = queue.delete(res.id)
    p res
    puts "shouldn't be any more"
    res = queue.get()
    p res
    assert_nil res

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
    assert_nil res

  end


  def test_queues_list
    queue_name = 'test_queues_list'
    @client.queue_name = queue_name
    clear_queue

    res = @client.messages.post("hello world!")
    p res 

    res = @client.queues.list
    res.each do |q|
      puts "#{q.name} and #{queue_name}";
      if q.name == queue_name
        assert_equal q.size, 1 
      end
    end
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

    msg_nil = @client.messages.get()
    p msg_nil
    assert_nil msg_nil

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      new_msg = @client.messages.get()
      p new_msg
      next if new_msg.nil?
      assert_equal new_msg.id, msg.id
      new_msg.delete
      break
    end
    assert_not_equal tries, 0

    # now try explicit timeout
    res = @client.messages.post("hello world timeout2!", :timeout => 5)
    p res
    msg = @client.messages.get()
    p msg
    assert msg
    msg_nil = @client.messages.get()
    p msg_nil
    assert_nil msg_nil

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      new_msg = @client.messages.get()
      next if new_msg.nil?
      assert_equal new_msg.id, msg.id
      break
    end
    assert_not_equal tries, 0

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
    assert_equal 0, res.size

  end

  def test_delay
    puts 'test_delay'
    @client.queue_name = "test_delay_6"
    clear_queue
    msgTxt = "testMessage-"+Time.now.to_s
    puts msgTxt
    @client.messages.post(msgTxt, {:delay => 5})
    msg = @client.messages.get
    p msg
    assert_nil msg

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      msg = @client.messages.get
      p msg
      next if msg.nil?
      assert_equal msg.body, msgTxt
      break
    end
    assert_not_equal tries, 0
    
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
    assert_equal 10, resp["ids"].size

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
    assert_equal msg_id, msg.id
    # Ok, so should have received same message, now let's release it quicker than the original timeout

    # but first, ensure the next get is nil
    msg = @client.messages.get
    p msg
    assert_nil msg

    # now release it instantly
    @client.messages.release(msg_id)
    msg = @client.messages.get
    p msg
    assert msg
    assert_equal msg_id,  msg.id

    # ok, so should be reserved again
    msgr = @client.messages.get
    p msgr
    assert_nil msgr

    # let's release it in 10 seconds
    @client.messages.release(msg_id, :delay => 10)
    msg = @client.messages.get
    p msg
    assert_nil msg

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      msg = @client.messages.get
      next if msg.nil?
      p msg
      assert_equal msg.id, msg_id
      break
    end
    assert_not_equal tries, 0

    msg.release(:delay => 5)
    msg = @client.messages.get
    p msg
    assert_nil msg

    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      msg = @client.messages.get
      next if msg.nil?
      p msg
      assert_equal msg.id, msg_id
      break
    end
    assert_not_equal tries, 0
  end


  def test_clear

    q = @client.queue("test_clear_7")

    clear_queue(q.name)

    val = "hi mr clean"
    q.post(val)

    sleep 0.5 # make sure the counter has time to update
    assert_equal 1, q.size

    q.clear

    msg = q.get
    assert_nil msg

    assert_equal 0, q.reload.size
  end



  def test_poll
    queue_name = "test_poll_6"
    @client.queue_name = queue_name
    clear_queue

    queue = @client.queue(queue_name)

    v = "hello world"
    5.times do
      queue.post(v)
    end

    i = 0
    queue.poll(:break_if_nil=>true) do |msg|
      assert msg.body.include?("hello")
      i += 1
    end

    assert_equal 5, i

    assert_equal 0, queue.reload.size

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

  def test_webhooks
    omit_if @skip
    puts "skip webhooks: #{@skip}"
    qname ="webhook_queue"
    path = "#{IronMQ::Messages.path(project_id: @client.project_id, queue_name: qname)}/webhook"
    url = "#{@client.base_url}#{path}"
    url << "?oauth=#{@client.token}"
    p url

    v = "hello webhook"

    @rest = Rest::Client.new
    p @rest.post(url, body: v)

    queue = @client.queue(qname)
    msg = queue.get
    p msg
    assert_equal v, msg.body


  end


end

