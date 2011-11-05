require 'yaml'
require 'concur'
begin
  require File.join(File.dirname(__FILE__), '../lib/ironmq')
rescue Exception => ex
  puts "Could NOT load current ironmq: " + ex.message
  raise ex
end

@config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "ironmq_gem", "test", "config.yml")))
@client = IronMQ::Client.new(@config['ironmq'])
@client.queue_name = 'ironmq-gem-tests'
@num_to_add = @config['count']

start = Time.now
puts "Queuing #{@num_to_add} items at #{start}..."
executor = Concur::Executor.new_thread_pool_executor(50)
@num_to_add.times do |i|
  task = executor.execute do
    begin
      puts "POST #{i}..."
      res = @client.messages.post("hello world! #{i}")
    rescue => ex
      puts "ERROR! #{ex.class.name}: #{ex.message} -- #{ex.backtrace.inspect}"
      raise ex
    end
  end
end

i = 0
while executor.queue_size > 0 do
  i += 1
  puts "waiting #{i}, queue size=#{executor.queue_size}"
  sleep 0.5
end


put_time = (Time.now.to_f - start.to_f)
puts "Finished pushing in #{put_time} seconds"

exit if true

start = Time.now
puts "Getting and deleting #{@num_to_add} items at #{start}..."
@num_to_add.times do |i|
  puts "GET #{i}..."
  res = @client.messages.get()
  p res
  puts "DELETE #{i}..."
  res = @client.messages.delete(res["id"])
  p res
end

puts "Finished pushing #{@num_to_add} items in #{put_time} seconds."
puts "Finished getting and deleting #{@num_to_add} items in #{(Time.now.to_f - start.to_f)} seconds."

executor.shutdown
