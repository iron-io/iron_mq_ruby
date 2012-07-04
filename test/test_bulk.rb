require_relative 'test_base'

class TestBulk < TestBase

  def setup
    super

  end

  def test_bulk

    q_name = 'ironmq-gem-bulk'
    queue = @client.queue(q_name)

    times = 50
    t = Time.now
    times.times do |i|
      puts "Posting #{i}"
      res = queue.post("hello world #{i}!")
    end
    puts "#{times} posts took #{Time.now.to_f - t.to_f}"

    t = Time.now
    res = nil
    while (res = queue.get())
      del = res.delete
    end
    puts "#{times} gets and deletes took #{Time.now.to_f - t.to_f}"

  end

end

