require 'quicky'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

TIMES = 1

class QuickRun < TestBase

  def setup
    super
  end

  def test_quick
    queue_name = 'ironmq-gem_quick'
    clear_queue(queue_name)
    queue = @client.queue(queue_name)

    quicky = Quicky::Timer.new

    # make connection
    res2 = queue.get
    # p res2

    quicky.loop(:test_quick, TIMES, :warmup => 2) do |i|
      puts "==== LOOP #{i} =================================="

      post_id = nil
      quicky.time(:post, :warmup => 2) do
        res = queue.post("hello world!")
        # p res
        assert_not_nil res
        assert_not_nil res.id
        post_id = res.id
        assert !(res.msg.nil? || res.msg.empty?)
      end

      quicky.time(:get, :warmup => 2) do
        msg = queue.get
        # p res
        puts "post_id=" + post_id.inspect
        assert_not_nil msg.id
        assert_equal msg.id, post_id
        assert !(msg.body.nil? || msg.body.empty?)
      end

      quicky.time(:delete, :warmup => 2) do
        res = queue.delete(post_id)
        # p res
        assert_not_nil res
        assert !(res.msg.nil? || res.msg.empty?)
      end

      msg = queue.get
      # p msg
      assert_nil msg


      q = @client.queue('test2')
      res = q.post("hello world!")
      # p res
      assert_not_nil res.id
      assert_not_nil res.msg

      msg = q.get
      # p res
      assert_not_nil msg
      assert_not_nil msg.id
      assert_not_nil msg.body

      res = msg.delete
      # p res
      assert_equal 200, res.code, "API must delete message and response with HTTP 200 status, but returned HTTP #{res.code}"
    end
    puts "count: #{quicky.results(:post).count}"
    puts "avg post: #{quicky.results(:post).duration}"
    puts "avg get: #{quicky.results(:get).duration}"
    puts "avg delete: #{quicky.results(:delete).duration}"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"

    resp = @client.queue('test2').delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


end

