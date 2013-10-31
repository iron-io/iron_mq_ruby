require 'rubygems'
require 'test/unit'
require 'yaml'
require 'uber_config'

begin
  require File.expand_path('../lib/iron_mq', File.dirname(__FILE__))
rescue Exception => ex
  puts "Could NOT load current iron_mq: " + ex.message
  raise ex
end

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO
MAX_TRIES = 10

class TestBase < Test::Unit::TestCase

  def setup
    puts 'setup'
    # check multiple config locations
    @config = UberConfig.load
    puts "config=" + @config.inspect

    config = @config['iron']
    @host = "#{config['host'] || "mq-aws-us-east-1.iron.io"}"

    @client = IronMQ::Client.new(@config['iron'])
    puts "IronMQ::VERSION = #{IronMQ::VERSION}"
    #Rest.logger.level = Logger::DEBUG # this doesn't work for some reason?
    #IronCore::Logger.logger.level = Logger::DEBUG

    @queue_name = 'ironmq-ruby-tests' # default queue for tests
  end


  def clear_queue(queue_name=nil)
    queue_name ||= @queue_name

    queue = @client.queue(queue_name)

    puts "clearing queue #{queue_name}"
    begin
      queue.clear
      puts 'cleared.'
    rescue Rest::HttpError => ex
      if ex.code == 404
        # this is fine
      else
        raise ex
      end
    end

  end

  def assert_performance(time)
    start_time = Time.now

    yield

    execution_time = Time.now - start_time

    assert execution_time < time, "Execution time too big #{execution_time.round(2)}, should be #{time}"
  end

end
