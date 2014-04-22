gem 'test-unit'
require 'test/unit'
require 'yaml'
require 'parallel'
require_relative 'test_base'

class TmpTests < TestBase
  def setup
    super

  end



  def test_poll
    queue_name = "test_poll_6"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)

    v = "hello world"
    5.times { queue.post(v) }

    i = 0
    queue.poll(:break_if_nil => true) do |msg|
      assert msg.body.include?("hello")
      i += 1
    end

    assert_equal 5, i

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_queue_delete
    queue = @client.queue("test_delete")
    queue.post("hi")
    old_id = queue.id
    queue.delete_queue

    LOG.info "sleeping for a bit to let queue delete..."
    sleep 60

    queue.post("hi2")
    # p queue
    assert_not_equal old_id, queue.id, "old queue ID (#{old_id}) must not be equal to new ID (#{queue.id})"
    assert_equal 1, queue.size, "queue size must be 1, but got #{queue.size}"

    msg = queue.get
    assert_equal "hi2", msg.body, "message body must be 'hi2', but got '#{msg.body}'"

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

  def test_webhooks
    qname ="webhook_queue"
    url = "#{@client.base_url}/#{qname}/messages/webhook?oauth=#{@client.token}"
    # p url

    v = "hello webhook"

    @rest = Rest::Client.new
    resp = @rest.post(url, :body => v)
    # p resp

    queue = @client.queue(qname)
    msg = queue.get
    # p msg
    assert_equal v, msg.body

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_queue_params

    qname = "test_queue_params_1"

    clear_queue(qname)
    q = @client.queue(qname)

    q.post("message 1", :timeout => 200, :delay => 0, :expires_in => 2000)
    q.post("message 1", :timeout => 300, :delay => 0, :expires_in => 3000)

    msgs = q.get(:n => 2)

    msgs.each do |m|
      puts m.body
      puts "timeout: #{m.timeout}"
      puts "expires_in: #{m.expires_in}"
      puts "delay: #{m.delay}"
    end

  end


  def test_reserved_count
    puts "test_reserved_count"

    queue_name = "test_reserved_count"
    clear_queue(queue_name)

    queue = @client.queue(queue_name)
    queue.post("zero message")
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"
    msg.release
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"
    msg.release
    msg = queue.get
    p msg
    puts "id: #{msg.id} reserved_count: #{msg.reserved_count}"


  end

  def test_queue_set_info
    qname = "test_queue_set_info"
    clear_queue(qname)
    q = @client.queue(qname)
    q.update_queue(:push_type => 'unicast')
    assert_equal 'unicast', q.push_type
    q.update_queue(:retries => 10)
    assert_equal 'unicast', q.reload.push_type
  end

  def test_dequeue_delete
    queue_name = "test_dequeue_delete_3"
    clear_queue(queue_name)
    queue = @client.queue(queue_name)
    v = "hello thou shalt only see me once"
    queue.post(v)
    assert_equal 1, queue.reload.size
    msg = queue.get(delete: true, timeout: 7)
    assert_equal v, msg.body
    sleep 1
    # get the queue again
    queue = @client.queue(queue_name)
    assert_equal 0, queue.size
    sleep 10
    msg = queue.get
    assert_nil msg
  end

  def test_long_polling
    queue_name = "test_long_polling"
    clear_queue(queue_name)
    queue = @client.queue(queue_name)
    msg = queue.get
    assert_nil msg
    v = "hello long"
    # ok, nothing in the queue, let's do a long poll
    starti = Time.now.to_i
    thr = Thread.new {
      sleep 5
      puts "Posting now"
      begin
        queue.post(v)
      rescue Exception => ex
        p ex
      end

    }
    puts "Now going to wait for it..."
    msg = queue.get(wait: 20)
    # p msg
    endi = Time.now.to_i
    duration = endi - starti
    p duration
    assert duration > 4 && duration <= 7
    assert_not_nil msg
    assert_equal v, msg.body
    msg.delete

  end


end

