require 'test/unit'
require 'yaml'
require File.expand_path('test_base.rb', File.dirname(__FILE__))

class IronMQTests < TestBase
  def setup
    super
    LOG.info "@host: #{@host}"

  end

  def test_basics
    queue_name = 'test_basics_71'
    clear_queue(queue_name)

    # NOTE: Kept for backward compatibility checking
    queue = @client.queue(queue_name)
    res = queue.post("hello world!")
    # p res

    assert res["id"]
    assert res.id
    assert res.msg
    sleep 0.3
    assert_equal 1, queue.reload.size

    message = queue.reserve
    # p res
    assert res["id"]
    assert res.id

    res = queue.delete(res["id"])
    # p res
    res = queue.reserve
    # p res
    assert_nil res

    sleep 0.3
    assert_equal 0, queue.reload.size

    res = queue.post("hello world 2!")
    # p res

    msg = queue.reserve
    # p msg
    assert msg

    res = msg.delete
    #p res

    res = queue.reserve
    # p res
    assert_nil res

    # new style of referencing queue
    queue = @client.queue(queue_name)
    v = "hello big world"
    res = queue.post(v)
    # p res
    assert res.msg

    res = queue.reserve
    puts "queue.reserve got: #{res.body}"
    p res
    assert res["id"]
    assert res.id
    assert_equal v, res.body

    res = queue.delete(res.id)

    res = queue.reserve
    # p res
    assert_nil res

    # test delete by item
    res = queue.post(v)
    # p res
    assert res.msg

    res = queue.reserve
    # p res
    assert res.body

    res = res.delete
    # p res
    res = queue.reserve
    # p res
    assert_nil res

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end



  def test_multi_delete
    puts 'test_multi_delete'
    queue_name = 'test_multi_delete_41'
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    ids = []
    10.times do |i|
      msg = queue.post("hello #{i}")
      ids << {id: msg.id}
    end
    sleep 0.5
    assert_equal 10, queue.reload.size

    queue.delete_messages(ids)
    sleep 1
    assert_equal 0, queue.reload.size

    # now try it with reserved messages
    ids = []
    10.times do |i|
      msg = queue.post("hello #{i}")
    end
    sleep 0.5
    assert_equal 10, queue.reload.size
    while (msg = queue.reserve) != nil do
      ids << {id: msg.id, reservation_id: msg.reservation_id}
    end
    queue.delete_messages(ids)
    sleep 1
    assert_equal 0, queue.reload.size

    queue.delete_queue



  end

  def test_reservation_ids
    puts 'test_reservation_ids'
    # get a message, let it timeout, then try to delete it. That should fail.
    queue_name = 'test_res_ids'
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    msg = queue.post("hello")
    msg = queue.reserve(:timeout=>3)
    sleep 3
    ex = assert_raise Rest::HttpError do
      msg.delete
    end
    assert_equal 403, ex.code

  end

  def test_queues_list
    queue_name = 'test_queues_list_1'
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    res = queue.post("hello world!")
    # p res

    res = @client.queues.list
    assert res.size > 0, "project must contain at least one queue"

    res.each do |q|
      # puts "#{q.name} and #{queue_name}"
      if q.name == queue_name
        assert_equal q.size, 1
      end
    end

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


end

