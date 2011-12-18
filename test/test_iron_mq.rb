# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

    puts 'clearing queue'
    while res = @client.messages.get()
      p res
      puts res.body.to_s
      res.delete
    end
    puts 'cleared.'

  end

  def test_basics

    res = @client.messages.post("hello world!")
    p res
    queue = @client.queues.get(:name=>@client.queue_name)
    assert queue.size == 1

    res = @client.messages.get()
    p res

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

    res = msg.delete
    p res

    puts "shouldn't be any more"
    res = @client.messages.get()
    p res
    assert res.nil?
  end

  # TODO: pass :timeout in post/get messages and test those
  def test_timeout
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
    puts "res.size=" + res.size.to_s
    res.each do |q|
      puts "queue_name: " + q.name
      puts "queue size: " + q.size.to_s
      assert q.size >= 0
    end
    assert res.size > 0

    res = @client.queues.list(:page=>5)
    puts "res.size 2=" + res.size.to_s
    res.each do |q|
      p q.name
    end
    assert res.size == 0


  end

  def test_delay
    # TODO
  end

end

