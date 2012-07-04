require 'concur'
require 'iron_mq'

class LongRunWorker

  attr_accessor :config, :num_to_add

  def run

    @client = IronMQ::Client.new(@config['iron'])
    @client.queue_name = 'ironmq-gem-long'

    @error_count = 0

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
          @error_count += 1
          raise ex
        end
      end
    end

    i = 0
    while executor.queue_size > 0 do
      i += 1
      puts "waiting #{i}, queue size=#{executor.queue_size}"
      sleep 2
    end


    put_time = (Time.now.to_f - start.to_f)
    puts "Finished pushing in #{put_time} seconds"

    #exit if true

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
    puts "Errors: #{@error_count}"

    executor.shutdown

  end

end