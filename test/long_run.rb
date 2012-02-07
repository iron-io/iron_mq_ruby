require 'yaml'
require 'concur'
begin
  require File.join(File.dirname(__FILE__), '..', 'lib', 'iron_mq')
rescue Exception => ex
  puts "Could NOT load current iron_mq: " + ex.message
  raise ex
end

require_relative 'long_run_worker'

@config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "iron_mq_ruby", "test", "config.yml")))
@num_to_add = @config['count']

IronWorker.configure do |c|
  c.token = @config['iron_mq']['token']
  c.project_id = @config['iron_mq']['project_id']
end

worker = LongRunWorker.new
worker.config = @config
worker.num_to_add = @num_to_add
#worker.run_local
worker.queue
status = worker.wait_until_complete
p status
puts worker.get_log



