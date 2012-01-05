gem 'test-unit'
require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/iron_mq')
rescue Exception => ex
  puts "Could NOT load current iron_mq: " + ex.message
  raise ex
end


class TestBase < Test::Unit::TestCase
  def setup
    puts 'setup'
    # check multiple config locations
    @config = load_config
    puts "config=" + @config.inspect
    @client = IronMQ::Client.new(@config['iron_mq'])
    @client.logger.level = Logger::DEBUG
    @client.queue_name = 'ironmq-ruby-tests'

  end

  def load_config
    # check for config
    if defined? $abt_config
      @config = $abt_config
      return @config
    end
    cf = File.expand_path(File.join("~", "Dropbox", "configs", "iron_mq_ruby", "test", "config.yml"))
    if File.exist?(cf)
      @config = YAML::load_file(cf)
      return @config
    end

  end
end
