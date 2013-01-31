require 'quicky'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

TIMES = 10

class QuickRun < TestBase

  def setup
    super
    @client.queue_name = 'ironmq-gem_quick'
    clear_queue
  end

  def test_quick

    quicky = Quicky::Timer.new

    # make connection
    res2 = @client.messages.get()
    p res2

    quicky.loop(:test_quick, TIMES, :warmup => 2) do |i|
      puts "==== LOOP #{i} =================================="

      post_id = nil
      quicky.time(:post, :warmup => 2) do
        res = @client.messages.post("hello world!")
        p res
        assert res.id
        post_id = res.id
        assert res.msg
      end

      quicky.time(:get, :warmup => 2) do
        res = @client.messages.get()
        p res
        puts "post_id=" + post_id.inspect
        assert res.id
        assert_equal res.id, post_id
        assert res.body
      end

      quicky.time(:delete, :warmup => 2) do
        res = @client.messages.delete(post_id)
        p res
        assert res.msg
      end

      res = @client.messages.get()
      p res
      assert res.nil?

      res = @client.messages.post("hello world!", :queue_name => 'test2')
      p res
      assert res.id
      assert res.msg

      res = @client.messages.get(:queue_name => 'test2')
      p res
      assert res.id
      assert res.body

      res = res.delete
      p res
    end
    puts "count: #{quicky.results(:post).count}"
    puts "avg post: #{quicky.results(:post).duration}"
    puts "avg get: #{quicky.results(:get).duration}"
    puts "avg delete: #{quicky.results(:delete).duration}"


  end


end

