# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'

class TestAlerts < TestBase

  def setup
    super
    @skip = @host.include? 'rackspace'
    return if @skip # bypass these tests if rackspace
  end

  def test_configuration
    q_name = 'bad-alerts-params'
    queue = @client.queue q_name
    delete_queues queue

    # no configuration
    alert = {}
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # only type is specified
    alert[:type] = 'fixed'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # type and trigger value specified
    alert[:trigger] = 30
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # type, trigger, and direction
    alert[:direction] = 'asc'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # type, trigger, direction, and alert queue name - alright
    aq_name = 'bad-alerts-params-alerts'
    alert[:queue] = aq_name
    assert_nothing_raised(Rest::HttpError) { queue.add_alert(alert) }

    # type, trigger, direction, queue name, and snooze - alright
    alert[:snooze] = 8
    assert_nothing_raised(Rest::HttpError) { queue.add_alert(alert) }

    # wrong snooze
    alert[:snooze] = -13
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    alert[:snooze] = '1234'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # wrong type
    alert[:snooze] = 0
    alert[:type] = 'wrong'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # wrong trigger
    alert[:type] = 'progressive'
    alert[:trigger] = 'c'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # wrong direction
    alert[:trigger] = 30
    alert[:direction] = 'both'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # delete queue to clear
    delete_queues queue

    # Test max alerts number
    alert[:direction] = 'asc'
    # insert 6 alerts
    assert_raise(Rest::HttpError) { queue.add_alerts(Array.new(6, alert)) }

    queue.add_alerts(Array.new(5, alert))
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    delete_queues queue

    # Cyclic alerts tests
    # Progressive alert posts to its queue (queue is the same as alert queue)
    alert[:queue] = q_name
    alert[:type] = 'progressive'
    assert_raise(Rest::HttpError) { queue.add_alert(alert) }

    # Q1 progressive alert posts to Q2, Q2 progressive alert posts to Q1
    a_queue = @client.queue aq_name
    queue.add_alert(alert.merge({:queue => aq_name}))
    assert_raise(Rest::HttpError) do
      a_queue.add_alert(alert.merge({:queue => q_name}))
    end
  end

  def test_size_alerts
    return if @skip

    type = 'fixed'
    trigger = 10
    # Test size alets, direction is ascending
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'asc')

    # queue size will be trigger + 3
    trigger_alert(queue, alert_queue, trigger, 3)

    # must not trigger alert, queue size will be trigger + 13
    post_messages(queue, 10)
    assert_queue_size 1, alert_queue

    # must not trigger alert, queue size will be trigger - 3
    delete_messages(queue, 16)
    assert_queue_size 1, alert_queue

    trigger_alert(queue, alert_queue, trigger)

    delete_queues(queue, alert_queue)

    # Test size alerts, direction is descending
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'desc')

    # must not trigger descending alert
    post_messages(queue, 15)
    assert_queue_size 0, alert_queue

    # will remove 5 msgs, queue size will be 10
    trigger_alert(queue, alert_queue, trigger)

    # must not trigger alert
    post_messages(queue, 12)
    assert_queue_size 1, alert_queue

    trigger_alert(queue, alert_queue, trigger)

    # must not trigger alert
    delete_messages(queue, 8)
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)

    # test ascending alert with snooze
    snooze = 10
    trigger = 10
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'asc', snooze)

    # Trigger alert
    post_messages(queue, trigger + 1)
    to_time = Time.now + snooze - 4
    assert_queue_size 1, alert_queue

    while (lambda { Time.now }).call < to_time do
      delete_messages(queue, 2) # queeu size is `trigger - 1`
      post_messages(queue, 2) # size is `trigger + 1`
      assert_queue_size 1, alert_queue
    end
    sleep 4

    delete_messages(queue, 2) # queeu size is `trigger - 1`
    post_messages(queue, 2) # size is `trigger - 1`
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)

    # test descending alert with snooze
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'desc', snooze)

    # Trigger alert
    post_messages(queue, trigger + 1)
    delete_messages(queue, 2)
    to_time = Time.now + snooze - 4
    assert_queue_size 1, alert_queue

    while (lambda { Time.now }).call < to_time do
      post_messages(queue, 2) # queeu size is `trigger + 1`
      delete_messages(queue, 2) # size is `trigger - 1`
      assert_queue_size 1, alert_queue
    end
    sleep 4

    post_messages(queue, 2) # size is `trigger + 1`
    delete_messages(queue, 2) # queeu size is `trigger - 1`
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)
  end

  def test_progressive_alerts
    return if @skip

    type = 'progressive'
    trigger = 10
    # Test ascending progressive alert
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'asc')

    # Trigger 3 alerts
    (1..3).each { |n| trigger_alert(queue, alert_queue, n * trigger) }

    # Must not trigger alerts
    delete_messages(queue, 15)
    assert_queue_size 3, alert_queue

    trig = (get_queue_size(queue) / trigger.to_f).ceil * trigger
    trigger_alert(queue, alert_queue, trig)

    # must not trigger alert
    delete_messages(queue, get_queue_size(queue) - 1)

    delete_queues(queue, alert_queue)

    # Test descending progressive alert
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'desc')

    # must not trigger alert
    post_messages(queue, 25)
    assert_queue_size 0, alert_queue

    # trigger descending alert twice
    2.downto(1) { |n| trigger_alert(queue, alert_queue, n * trigger) }

    # must not trigger alert at size of 0
    delete_messages(queue, 5)
    assert_queue_size 2, alert_queue

    # must not trigger alert
    post_messages(queue, 15)
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)

    # test ascending alert with snooze
    snooze = 10
    trigger = 3
    queue, alert_queue = clear_queue_add_alert(type, trigger, 'asc', snooze)

    # Trigger alert
    post_messages(queue, trigger + 1)
    # Get current time as snooze start time
    to_time = Time.now + snooze - 4
    # Check queue for alert
    assert_queue_size 1, alert_queue

    while (lambda { Time.now }).call < to_time do
      # will trigger alert if snooze does not work
      post_messages(queue, trigger + 1)
      # but must not trigger
      assert_queue_size 1, alert_queue
    end
    sleep 4

    # Trigger alert again
    post_messages(queue, trigger + 1)
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)

    # test descending alert with snooze
    queue, alert_queue = clear_queue_add_alert(type, 2, 'desc', snooze)

    # Does not trigger alert
    post_messages(queue, 20 * trigger)
    to_time = Time.now + snooze - 4

    while (lambda { Time.now }).call < to_time do
      delete_messages(queue, trigger + 1)
      assert_queue_size 1, alert_queue
      break if get_queue_size(queue) <= trigger
    end
    sleep 4

    post_messages(queue, trigger + 1)
    delete_messages(queue, trigger)
    assert_queue_size 2, alert_queue

    delete_queues(queue, alert_queue)
  end

  def test_snooze_concurrent
    assert false, 'NOT IMPLEMENTED'
  end

  def post_messages(queue, n)
    per_100, last_n = (n > 100) ? [n / 100, n % 100] : [0, n]

    per_100.times { queue.post(Array.new(100, { :body => 'message' })) }

    queue.post(Array.new(last_n, { :body => 'message' })) if last_n > 0
  end

  def delete_messages(queue, n)
    per_100, last_n = (n > 100) ? [n / 100, n % 100] : [0, n]

    per_100.times { [queue.get(:n => last_n)].flatten.each { |msg| msg.delete } }

    [queue.get(:n => last_n)].flatten.each { |msg| msg.delete } if last_n > 0
  end

  def delete_queues(*queues)
    queues.each do |q|
      begin
        q.delete_queue
      rescue Rest::HttpError => ex
        if ex.code == 404
          Rest.logger.info("Delete queue got 404, ignoring.")
          # return ResponseBase as normal
          return nil
        else
          raise ex
        end
      end
    end
  end

  def trigger_alert(queue, alert_queue, trigger, overhead = 0)
    puts "trigger_alert(), called at #{caller[0]}"

    qsize = get_queue_size(queue)
    puts "Initial queue size is #{qsize}"
    puts 'Alert is already triggered!' if qsize == trigger
    aq_size = get_queue_size(alert_queue)

    if qsize < trigger
      nmsgs = trigger - qsize - 1
      puts "Try to trigger ascending alert... post #{nmsgs} messages"
      post_messages(queue, nmsgs)
    else
      nmsgs = qsize - trigger - 1
      puts "Try to trigger descending alert... delete #{nmsgs} messages"
      delete_messages(queue, nmsgs)
    end
    assert_queue_size aq_size, alert_queue, 'Alert is triggered, but must not be'

    if qsize < trigger
      puts "Post #{1 + overhead} more message(s)"
      post_messages(queue, 1 + overhead)
    else
      puts "Delete #{1 + overhead} more message(s)"
      delete_messages(queue, 1 + overhead)
    end
    assert_queue_size aq_size + 1, alert_queue, 'Alert is not triggered, but must be'
  end

  def clear_queue_add_alert(type, trigger, direction, snooze = nil)
    puts "clear_queue_add_alert(), called at #{caller[0]}"

    qname = "#{type}-#{direction}-#{trigger}-#{snooze || 'no_snooze'}"
    alert_qname = "#{qname}-alerts"

    queue = @client.queue(qname)
    alert_queue = @client.queue(alert_qname)
    # delete instead of clearing to remove all alerts from queue
    delete_queues(queue, alert_queue)
    # todo: should :queue be called something else,
    # like alert_queue? or url and have to use ironmq:// url?
    r = queue.add_alert({ :type => type,
                          :trigger => trigger,
                          :queue => alert_qname,
                          :direction => direction,
                          :snooze => snooze.to_i })
    #p r

    alerts = queue.alerts
    #p alerts

    assert_equal 1, alerts.size
    alert = alerts[0]
    #p alert
    assert_equal type, alert.type
    assert_equal trigger, alert.trigger
    assert_equal alert_qname, alert.queue
    assert_equal direction, alert.direction

    [queue, @client.queue(alert_qname)]
  end

  def get_queue_size(queue)
    begin
      queue.reload.size
    rescue Rest::HttpError => ex
      ex.message =~ /404/ ? 0 : raise(ex)
    end
  end

  def assert_queue_size(size, queue, msg = nil)
    puts "assert_queue_size(), called at #{caller[0]}"
    sleep 1
    assert_equal size, get_queue_size(queue), msg.to_s
  end

end
