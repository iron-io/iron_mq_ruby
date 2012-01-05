# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

#$abt_config = {:hello=>'abt_config_ya'}

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

    clear_queue()

  end


  def test_basics
    @client.queue_name = 'test_basics'
    clear_queue

    res = @client.messages.post("hello world!")
    p res
    assert res["id"]
    assert res.id
    assert res.msg

    queue = @client.queues.get(:name=>@client.queue_name)
    assert queue.size == 1

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

    queue = @client.queues.get(:name=>@client.queue_name)
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
  end

  # TODO: pass :timeout in post/get messages and test those
  def test_timeout
    @client.queue_name = "test_timeout"
    clear_queue

    res = @client.messages.post("hello world timeout!")
    p res

    msg = @client.messages.get()
    p msg

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
    assert msg.id == msg2.id

    msg2.delete

  end

  def test_queues
    res = @client.queues.list()
    puts "res.size: " + res.size.to_s
    res.each do |q|
      puts "queue_name: " + q.name
      puts "queue size: " + q.size.to_s
      assert q.size >= 0
    end
    assert res.size > 0

    res = @client.queues.list(:page=>5)
    puts "res.size 2: " + res.size.to_s
    res.each do |q|
      p q.name
    end
    assert res.size == 0


  end

  def test_delay
    puts 'test_delay'
    @client.queue_name = "test_delay"
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
    @client.queue_name = "test_batch"
    clear_queue

    x = []
    10.times do |i|
      x << {:body=>"body #{i}"}
    end
    resp = @client.messages.post(x)
    assert resp["ids"]
    assert resp["ids"].is_a?(Array)
    assert resp["ids"].size == 10

    msg = @client.messages.get()
    assert msg
    assert msg['id']
    msg.delete

    msgs = @client.messages.get(:n=>10)
    assert msgs.is_a?(Array)
    assert msgs.size == 9, "size should be 9, but it's #{msgs.size}"
    assert msgs[0]["id"]

    msgs.each do |m|
      m.delete
    end


  end

end

