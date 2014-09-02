require 'quicky'
require 'go'
require 'pp'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

THREADS = 10
TIMES_PER_THREAD = 1000

class QuickRun < TestBase

  def setup
    super
  end

  def test_quick
    Go.logger.level = Logger::DEBUG
    Concur.logger.level = Logger::DEBUG
    ch = Go::Channel.new
    results = nil

    (THREADS-1).times do |ti|

        go do
          do_it(ch, ti)
        end

      end

    ch.each do |r|
      puts "results: #{r.inspect}"
      if results
        results.merge!(r)
      else
        results = r
      end
    end
    pp results.to_hash

  end

  def do_it(ch, ti)

    begin

      queue_name = "ironmq_gem_quick_#{ti}_#{rand(1000)}"
      clear_queue(queue_name)
      queue = @client.queue(queue_name)

      quicky = Quicky::Timer.new
      consumer_ch = Go::Channel.new
      quicky.loop(:test_quick, TIMES_PER_THREAD) do |i|
        puts "==== LOOP t#{ti} - #{i} =================================="

        if i == 50 || i == TIMES_PER_THREAD-1
          start_consumer(quicky, queue, consumer_ch)
        end

        post_id = nil
        quicky.time(:post) do
          res = queue.post("hello world!")
          # p res
          assert_not_nil res
          assert_not_nil res.id
          post_id = res.id
          assert !(res.msg.nil? || res.msg.empty?)
        end

      end
      # wait for consumer to end
      #i = 0
      #consumer_ch.each do |r|
      #  i+=1
      #  puts "consumer #{r}"
      #  consumer_ch.close if i == TIMES_PER_THREAD
      #end
      sleep TIMES_PER_THREAD / 2

      puts "count: #{quicky.results(:post).count}"
      puts "avg post: #{quicky.results(:post).duration}"
      puts "avg get: #{quicky.results(:get).duration}"
      puts "avg delete: #{quicky.results(:delete).duration}"
      puts "queue size: #{queue.reload.size}"
      resp = queue.delete_queue
      assert_equal 200, resp.code, "API must respond with HTTP 200 status, but returned HTTP #{resp.code}"

      ch << quicky.results

    rescue Exception => ex
      p ex
      p ex.backtrace
    end

  end

  def start_consumer(quicky, queue, channel)
    go do
      while true do
        msg = nil
        quicky.time(:get) do
          msg = queue.get
        end
        if msg.nil?
          channel << "done"
          break
        end
        quicky.time(:delete) do
          msg.delete
        end
      end
    end
  end

end

