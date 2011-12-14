gem 'test-unit'
require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/ironmq')
rescue Exception => ex
  puts "Could NOT load current ironmq: " + ex.message
  raise ex
end


class TestBase < Test::Unit::TestCase
 def setup
    puts 'setup'
    @config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "ironmq_ruby", "test", "config.yml")))
    @client = IronMQ::Client.new(@config['ironmq'])
    @client.logger.level = Logger::DEBUG
    @client.queue_name = 'ironmq-ruby-tests'

  end
end
