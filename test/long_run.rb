require 'yaml'
require 'concur'
require 'uber_config'

unless Hash.instance_methods.include?(:default_proc=)
  class Hash
    def default_proc=(proc)
    end
  end
end

begin
  require File.join(File.dirname(__FILE__), '..', 'lib', 'iron_mq')
rescue Exception => ex
  puts "Could NOT load current iron_mq: " + ex.message
  raise ex
end

require_relative 'long_run_worker'

@config = UberConfig.load
@num_to_add = 10000

p @config

worker = LongRunWorker.new
worker.config = @config
worker.queue_name = "concur8"
worker.num_threads = 100
worker.num_to_add = @num_to_add
worker.skip_get_and_delete = false
worker.run
#worker.queue
#status = worker.wait_until_complete
#p status
#puts worker.get_log



