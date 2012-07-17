require 'yaml'
require 'concur'
require 'uber_config'
begin
  require File.join(File.dirname(__FILE__), '..', 'lib', 'iron_mq')
rescue Exception => ex
  puts "Could NOT load current iron_mq: " + ex.message
  raise ex
end

require_relative 'long_run_worker'

@config = UberConfig.load
@num_to_add = 1000

worker = LongRunWorker.new
worker.queue_name = "concur5"
worker.config = @config
worker.num_to_add = @num_to_add
worker.run
#worker.queue
#status = worker.wait_until_complete
#p status
#puts worker.get_log



