gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

    @queue_name = "fixed_num2_migration"

  end

  #def test_put_x
  #  q = @client.queue(@queue_name)
  #  1000.times do |i|
  #    puts "#{i}"
  #    q.post("msg #{i}")
  #  end
  #  p q.reload.size
  #  assert_equal 1800, q.size
  #end
  #
  def test_get_x
    #q = @client.queue(@queue_name)
    #puts "q.size: #{q.size}"
    #100.times do |i|
    # puts "#{i}"
    #  msg = q.get
    #  msg.delete
    #end
    #p q.reload.size
    #assert_equal 900, q.reload.size
  end
  #
  #def test_poll_all
  #  q = @client.queue(@queue_name)
  #  puts "q.size: #{q.size}"
  #  q.poll do |msg|
  #    p msg
  #  end
  #  p queue.reload.size
  #end


end
