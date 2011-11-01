# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/ironmq')
rescue Exception => ex
  puts "Could NOT load current ironmq: " + ex.message
  raise ex
end

class IronMQTests < Test::Unit::TestCase
  def setup
    puts 'setup'
    @config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "ironmq_gem", "test", "config.yml")))
    @client = IronMQ::Client.new(@config['ironmq'])
    @client.logger.level = Logger::DEBUG
    @client.queue_name = 'ironmq-gem-tests'

    puts 'clearing queue'
    res = nil
    while res != nil
      res = @client.messages.get()
      p res
      puts res.body.to_s
      res.delete
    end
    puts 'cleared.'

  end

  def test_basics
    res = @client.messages.post("hello world!")
    p res

    res = @client.messages.get()
    p res

    res = @client.messages.delete(res["id"])
    p res
    puts "shouldn't be any more"
    res = @client.messages.get()
    p res
    assert res.nil?

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
end

