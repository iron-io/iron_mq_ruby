require File.expand_path('test_base.rb', File.dirname(__FILE__))

class TestBulk < TestBase

  def setup
    super

  end

  def test_bulk
    LOG.info "test_bulk"

    q_name = 'ironmq-gem-bulk'
    queue = @client.queue(q_name)

    times = 50
    t = Time.now
    times.times do |i|
      puts "Posting #{i}"
      res = queue.post("hello world #{i}!")
    end
    LOG.info "#{times} posts took #{Time.now.to_f - t.to_f}"

    t = Time.now
    res = nil
    while (res = queue.get())
      del = res.delete
    end
    LOG.info "#{times} gets and deletes took #{Time.now.to_f - t.to_f}"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

end

