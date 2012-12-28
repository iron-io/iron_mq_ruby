require_relative 'test_base'

TIMES = 1

class QuickRun < TestBase

  def setup
    super
    @client.queue_name = 'ironmq-gem_quick'
    clear_queue
  end

  def test_basics

    TIMES.times do |i|
      puts "==== LOOP #{i} =================================="

      res = @client.messages.post("hello world!")
      p res
      assert res.id
      post_id = res.id
      assert res.msg

      res = @client.messages.get()
      p res
      puts "post_id=" + post_id.inspect
      assert res.id
      assert_equal res.id, post_id
      assert res.body

      res = @client.messages.delete(res["id"])
      p res
      assert res.msg

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


  end


end

