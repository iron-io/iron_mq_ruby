require_relative 'test_base'

class TestBulk < TestBase

  def setup
    super

  end

  def test_bulk

    q_name = 'ironmq-gem-bulk'
    queue = @client.queue(q_name)

    1000.times do |i|
      puts "Posting #{i}"
      res = queue.post("hello world #{i}!")
    end

    res = nil
    while (res = queue.get())
      del = res.delete
    end

  end

end

