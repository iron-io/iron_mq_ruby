# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'

class TestPushQueues < TestBase

  def setup
    super
    @skip = @host.include? 'rackspace'
    return if @skip # bypass these tests if rackspace
  end

  def test_size_alerts
    return if @skip

    # Add a normal size alert
    # Post x messages
    # check to ensure alert was triggered

    x = rand(1000)
    qname = "alert-queue-#{x}"
    clear_queue(qname)
    queue = @client.queue(qname)
    puts "queue: #{queue}"
    trigger_value = 10
    # todo: should :queue be called something else, like target_queue? or url and have to use ironmq:// url?
    target_queue_name = "alert-target-queue-#{x}"
    r = queue.add_alert({:type => "size", :trigger => trigger_value, :queue => target_queue_name})
    p r

    alerts = queue.alerts
    p alerts
    assert_equal 1, alerts.size
    alert = alerts[0]
    assert_equal "size", alert.type
    assert_equal trigger_value, alert.trigger
    assert_equal target_queue_name, alert.queue

    target_queue = @client.queue(target_queue_name)
    assert_equal 0, target_queue.size

    (trigger_value - 1).times do |i|
      puts "posting #{i}"
      queue.post("message #{i}")
    end
    sleep 0.5
    assert_equal 0, target_queue.size
    queue.post("message #{trigger_value}")
    sleep 0.5
    assert_equal trigger_value, queue.size
    assert_equal 1, target_queue.size

    # now let's get it down the reset point and trigger it again
    (trigger_value / 2).times do |i|
      m = queue.get
      m.delete
    end
    assert_equal trigger_value/2, queue.size
    assert_equal 1, target_queue.size

    # once it's at half, it should reset so let's get it back up to trigger_value again
    (trigger_value / 2).times do |i|
      queue.post("second set: message #{i}")
    end
    sleep 0.5
    assert_equal trigger_value, queue.size
    assert_equal 2, target_queue.size

    queue.delete_queue
    target_queue.delete_queue

  end


  def test_progressive_alerts
    return if @skip

    # Add a normal size alert
    # Post x messages
    # check to ensure alert was triggered

    x = rand(1000)
    qname = "alert-queue-#{x}"
    queue = @client.queue(qname)
    trigger_value = 10
    # todo: should :queue be called something else, like target_queue? or url and have to use ironmq:// url?
    target_queue_name = "alert-target-queue-#{x}"
    r = queue.add_alert({:type => "progressive", :trigger => trigger_value, :queue => target_queue_name})
    p r

    alerts = queue.alerts
    assert_equal 1, alerts.size
    alert = alerts[0]
    assert_equal "progressive", alert.type
    assert_equal trigger_value, alert.trigger
    assert_equal target_queue_name, alert.queue

    target_queue = @client.queue(target_queue_name)
    assert_equal 0, target_queue.size

    post_messages(queue, trigger_value)
    assert_equal trigger_value, queue.size
    assert_equal 1, target_queue.size

    # now let's do it again and see if it tiggers again
    post_messages(queue, trigger_value)
    assert_equal trigger_value * 2, queue.size
    assert_equal 2, target_queue.size

    # now let's do it once again and see if it triggers again
    post_messages(queue, trigger_value)
    assert_equal trigger_value * 3, queue.size
    assert_equal 3, target_queue.size

    # now let's get it down to the reset point and trigger it again
    (trigger_value).times do |i|
      m = queue.get
      m.delete
    end
    sleep 0.5
    assert_equal trigger_value*2, queue.size
    assert_equal 3, target_queue.size

    # once it's at half, it should reset so let's get it back up to trigger_value again
    post_messages(queue, trigger_value)
    assert_equal trigger_value*3, queue.size
    assert_equal 4, target_queue.size

    queue.delete_queue
    target_queue.delete_queue

  end

  def post_messages(queue, num)
    (num).times do |i|
      queue.post("message #{i}")
    end
    sleep 0.5
  end


end
