require 'quicky'
require 'go'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

TIMES_PER_THREAD = (ARGV[0] || 1000).to_i

class QuickRun < TestBase

  def setup
    super
  end

  def test_quick

    queue_name = "ironmq_gem_quick_#{rand(100)}"
    clear_queue(queue_name)
    clear_queue(queue_name + '_2')
    queue = @client.queue(queue_name)

    quicky = Quicky::Timer.new
    j = 0
    quicky.loop(:test_quick, TIMES_PER_THREAD) do |i|
      puts "==== LOOP #{(i || j) + 1} / #{TIMES_PER_THREAD} =================================="
      j += 1

      post_id = nil
      body = "Hello world!\nHello Everyone!!"

      quicky.time(:post) do
        res = queue.post(body)
        # p res
        assert_not_nil res
        assert_not_nil res.id
        post_id = res.id
        assert !(res.msg.nil? || res.msg.empty?)
      end

      quicky.time(:get) do
        msg = queue.get
        assert_not_nil msg.id
        assert_equal msg.id, post_id
        assert_equal msg.body, body
      end

      quicky.time(:delete) do
        res = queue.delete(post_id)
        # p res
        assert_not_nil res
        assert !(res.msg.nil? || res.msg.empty?)
      end

      msg = queue.get
      # p msg
      assert_nil msg


      q = @client.queue(queue_name + '_2')
      res = q.post(body)
      # p res
      assert_not_nil res.id
      assert_not_nil res.msg

      msg = q.get
      # p res
      assert_not_nil msg
      assert_not_nil msg.id
      assert_not_nil msg.body

      assert_equal body, msg.body

      res = msg.delete
      # p res
      assert_equal 200, res.code, "API must delete message and respond with HTTP 200 status, but returned HTTP #{res.code}"
    end
    puts "count: #{quicky.results(:post).count}"
    puts "avg post: #{quicky.results(:post).duration}"
    puts "avg get: #{quicky.results(:get).duration}"
    puts "avg delete: #{quicky.results(:delete).duration}"
    puts "queue size: #{queue.reload.size}"
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must respond with HTTP 200 status, but returned HTTP #{resp.code}"


  end

end

