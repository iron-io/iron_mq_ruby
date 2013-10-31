require 'quicky'
require 'go'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

TIMES_PER_THREAD = 10

class QuickRun < TestBase

  def setup
    super
  end

  def test_quick

    queue_name = "ironmq_gem_quick_#{rand(100)}"
    clear_queue(queue_name)
    queue = @client.queue(queue_name)

    quicky = Quicky::Timer.new
    j = 0
    quicky.loop(:test_quick, TIMES_PER_THREAD) do |i|
      puts "==== LOOP #{i || j} =================================="
      j += 1
      body = "hello world!"
      post_id = nil
      quicky.time(:post) do
        puts "post"
        res = queue.post(body)
        # p res
        assert_not_nil res
        assert_not_nil res.id
        post_id = res.id
        assert !(res.msg.nil? || res.msg.empty?)
      end

      quicky.time(:get) do
        puts "get"
        msg = queue.get
        assert_not_nil msg.id
        assert_equal msg.id, post_id
        assert !(msg.body.nil? || msg.body.empty?)
        assert_equal body, msg.body
      end

      quicky.time(:delete) do
        puts "delete"
        res = queue.delete(post_id)
        # p res
        assert_not_nil res
        assert !(res.msg.nil? || res.msg.empty?)
      end

      msg = queue.get
      # p msg
      assert_nil msg

    end
    puts "count: #{quicky.results(:post).count}"
    puts "avg post: #{quicky.results(:post).duration}"
    puts "avg get: #{quicky.results(:get).duration}"
    puts "avg delete: #{quicky.results(:delete).duration}"
    puts "queue size: #{queue.reload.size}"
    assert_equal 0, queue.size
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must respond with HTTP 200 status, but returned HTTP #{resp.code}"


  end

end

