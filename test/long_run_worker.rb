require 'concur'
require 'iron_mq'

class LongRunWorker

  attr_accessor :config, :num_to_add, :queue_name, :skip_get_and_delete, :num_threads

  def run

    @client = IronMQ::Client.new(@config['iron'])
    queue = @client.queue(queue_name)

    @error_count = 0

    start = Time.now
    puts "Queuing #{@num_to_add} items at #{start}..."
    executor = Concur::Executor.new_thread_pool_executor(num_threads || 20)
    @num_to_add.times do |i|
      task = executor.execute do
        begin
          puts "POST #{i}..."
          res = queue.post("hello world! #{i}")
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
    sleep 1
    puts "Finished pushing in #{put_time} seconds"

    queue = @client.queue(queue_name)
    queue_size_after_push = queue.size
    puts "QUEUE SIZE: #{queue_size_after_push}"

    #exit if true

    if skip_get_and_delete
      start = Time.now
      puts "Getting and deleting #{@num_to_add} items at #{start}..."
      @num_to_add.times do |i|
        task = executor.execute do
          puts "GET #{i}..."
          res = queue.get()
          p res
          puts "DELETE #{i}..."
          res = queue.delete(res.id)
          p res
        end
      end
      i = 0
      while executor.queue_size > 0 do
        i += 1
        puts "waiting #{i}, queue size=#{executor.queue_size}"
        sleep 2
      end
      sleep 1
    end

    queue = @client.queue(queue_name)

    puts "Finished pushing #{@num_to_add} items in #{put_time} seconds."
    puts "QUEUE SIZE after push: #{queue_size_after_push}"
    puts "Finished getting and deleting #{@num_to_add} items in #{(Time.now.to_f - start.to_f)} seconds."
    puts "QUEUE SIZE after delete: #{queue.size}"
    puts "Errors: #{@error_count}"

    executor.shutdown

  end

end