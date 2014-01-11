# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'

class TestPushQueues < TestBase

  def setup
    super
  end

  def make_key(i, t, random=0)
    key = "pushq-#{t}-#{i}-#{random}"
  end

  def test_subscriber_add_remove
    puts "test_subscriber_add_remove"
    qname = "subscribers_add_remove_test"
    s = "http://nowhere.com:8080/somepath"
    s2 = "http://somewhere.com"
    queue = @client.queue(qname)
    subscribers = [{:url => s}]
    res = queue.update_queue(:subscribers => subscribers)
    LOG.debug queue.subscribers
    assert_equal 1, queue.subscribers.size

    queue.reload
    assert_equal 1, queue.subscribers.size
    p queue.subscribers[0].url
    queue.remove_subscriber({:url => s})
    queue.reload
    assert_equal 0, queue.subscribers.size
    p queue.subscribers

    # add it back with add
    queue.add_subscriber({:url => s})
    queue.reload
    assert_equal 1, queue.subscribers.size
    p queue.subscribers[0].url
    queue.remove_subscriber({:url => s})
    queue.reload
    assert_equal 0, queue.subscribers.size
    p queue.subscribers

    # add two, remove first
    queue.add_subscriber({:url => s})
    queue.add_subscriber({:url => s2})
    queue.reload
    assert_equal 2, queue.subscribers.size
    p queue.subscribers[0].url
    queue.remove_subscriber({:url => s})
    queue.reload
    assert_equal 1, queue.subscribers.size
    p queue.subscribers[0].url
    assert_equal s2, queue.subscribers[0].url

    queue.delete_queue
  end


  def test_queue_subscriptions
    puts "test_queue_subscriptions"
    types = ["multicast", "unicast"]
    # to delete queues later (clear project)
    queue_names = []
    types.each do |t|

      LOG.info "Trying type #{t}"

      qname = "subscription-queue-#{t}"
      queue_names << qname

      num_subscribers = 10
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {:url => "http://rest-test.iron.io/code/200?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)

      LOG.debug queue.subscribers
      assert_equal num_subscribers, queue.subscribers.size

      # add the last one
      queue.reload # temporary, can remove
      queue.add_subscriber({:url => "http://nowhere.com"})
      queue.reload
      assert_equal num_subscribers + 1, queue.subscribers.size
      queue.remove_subscriber({:url => "http://nowhere.com"})
      queue.reload
      assert_equal num_subscribers, queue.subscribers.size

      # todo: assert subscriptions match

      msg = "hello #{x}"
      m = queue.post(msg)

      LOG.info "Checking results..."
      @rest = Rest::Client.new
      found = 0
      if t == "multicast"
        num_subscribers.times do |i|
          key = make_key(i, t, x)
          tries = MAX_TRIES
          while tries > 0
            tries -= 1
            sleep 1
            begin
              url = "http://rest-test.iron.io/stored/#{key}"
              LOG.info "checking url #{url}"
              response = @rest.get(url)
              p response.body
              parsed = JSON.parse(response.body)
              LOG.debug parsed['body']
              assert_equal msg, parsed['body']
              found += 1
              break
            rescue Rest::HttpError => ex
              LOG.debug ex.code
              assert_equal 404, ex.code
            end
          end
          assert_not_equal tries, 0
        end
      elsif t == "unicast"
        tries = MAX_TRIES
        while tries > 0
          tries -= 1
          sleep 0.5
          num_subscribers.times do |i|
            key = make_key(i, t, x)
            begin
              url = "http://rest-test.iron.io/stored/#{key}"
              LOG.info "checking url #{url}"
              response = @rest.get(url)
              parsed = JSON.parse(response.body)
              LOG.debug parsed['body']
              assert_equal msg, parsed['body']
              found += 1
              break
            rescue Rest::HttpError => ex
              LOG.debug ex.code
              assert_equal 404, ex.code
            end
          end
          break if found == 1
        end
        assert_not_equal tries, 0
      end

      tries = MAX_TRIES
      while tries > 0

        # Need to wait > 60s here, because in case of retries on pusherd
        # side (due lost connection for example) there will be no response earlier
        # (default retries_delay is 60s).
        sleep 1
        tries -= 1
        # old style of message getting
        msg = queue.messages.get(m.id)
        LOG.info "checking for message: #{msg}"
        next if msg.nil?
        subscribers = msg.subscribers

        LOG.debug subscribers
        if t == "unicast"
          assert_equal 1, found
          assert_equal 1, subscribers.size
        else # pubsub
          assert_equal num_subscribers, found
          assert_equal num_subscribers, subscribers.size
        end

        do_retry = false
        subscribers.each do |s|
          LOG.debug s
          LOG.info "status_code=#{s['status_code']}"
          LOG.info "status=#{s['status']}"
          do_retry = true unless 200 == s["status_code"]
          do_retry = true unless "deleted" == s["status"]
        end
        next if do_retry
        break
      end
      assert_not_equal tries, 0

      # delete queue after all tests on it were completed
      resp = queue.delete_queue
      assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
    end
  end

  def test_headers
    puts "test_headers"
    qname = "push-headers"
    subscribers = []

    x = rand(1000)
    key = "somemsg_#{x}"
    subscribers << {:url => "http://rest-test.iron.io/code/200?store=#{key}",
    :headers=>{"Content-Type"=>"application/json"}}

    queue = @client.queue(qname)
    queue.update_queue(:subscribers => subscribers,
                       :push_type => "multicast")

    LOG.debug queue.subscribers
    assert_equal subscribers.size, queue.subscribers.size
    queue.reload.subscribers.each do |s|
      p s.headers
      assert_not_nil s.headers['Content-Type']
    end

    msg = "{\"hello\": #{x}}"
    m = queue.post(msg)

    LOG.info "Checking results..."
    @rest = Rest::Client.new
    found = 0
    tries = MAX_TRIES
    while tries > 0
      tries -= 1
      sleep 1
      begin
        url = "http://rest-test.iron.io/stored/#{key}"
        LOG.info "checking url #{url}"
        response = @rest.get(url)
        p response.body
        parsed = JSON.parse(response.body)
        LOG.debug parsed['body']
        assert_equal msg, parsed['body']
        assert_not_nil parsed['headers']['Content-Type']
        assert_equal 'application/json', parsed['headers']['Content-Type']
        break
      rescue Rest::HttpError => ex
        LOG.debug ex.code
        assert_equal 404, ex.code
      end
      assert_not_equal tries, 0
    end

    # delete queue after all tests on it were completed
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must respond with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_failure
    @rest = Rest::Client.new
    qname = "failure-queue"

    x = rand(1000)

    subscribers = []
    subscribers << {:url => "http://rest-test.iron.io/code/503?switch_after=2&switch_to=200&namespace=push-test-failures-#{x}"}
    subscribers << {:url => "http://rest-test.iron.io/code/503"}

    num_subscribers = 2

    queue = @client.queue(qname)
    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => "multicast",
                             :retries => 3,
                             :retries_delay => 3
    )
    queue = @client.queue(qname)
    LOG.debug queue
    LOG.debug queue.subscribers
    assert_equal num_subscribers, queue.subscribers.size

    msg = "hello #{x}"
    m = queue.post(msg)
    LOG.debug m

    tries = MAX_TRIES
    while tries > 0
      sleep 0.5
      tries -= 1
      LOG.info 'getting status'
      subscribers = queue.messages.get(m.id).subscribers
      LOG.debug subscribers
      LOG.info "num_subscribers=#{num_subscribers} subscribers.size=#{subscribers.size}"

      assert_equal num_subscribers, subscribers.size
      do_retry = false
      subscribers.each do |s|
        LOG.debug s
        LOG.info "status_code=#{s['status_code']}"
        LOG.info "status=#{s['status']}"
        do_retry = true unless 503 == s["status_code"]
        do_retry = true unless ["reserved", "retrying"].include? s["status"]
      end
      next if do_retry
      break
    end
    assert_not_equal tries, 0

    tries = MAX_TRIES
    while tries > 0
      puts 'sleeping for 5 to wait for retry'
      sleep 5
      tries -= 1
      subscribers = queue.messages.get(m.id).subscribers
      LOG.debug subscribers
      assert_equal num_subscribers, subscribers.size
      do_retry = false
      subscribers.each do |s|
        LOG.debug s
        if s["url"] == "http://rest-test.iron.io/code/503"
          if "error" == s["status"]
            assert_equal 0, s["retries_remaining"]
          else
            assert_equal 503, s["status_code"]
            do_retry = true
          end
        else
          # this one should error a couple times, then be successful
          LOG.info "retries_remaining: #{s["retries_remaining"]}"
          if ["deleted", "error"].include? s["status"] || 200 == s["status_code"]
            assert_equal 0, s["retries_remaining"]
          else
            do_retry = true
          end
        end
      end
      next if do_retry
      break
    end
    assert_not_equal tries, 0

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


  def test_202
    puts "test_202"
    types = ["multicast"]
    types.each do |t|

      LOG.info "Trying type #{t}"

      qname = "subscription-queue-#{t}-202"

      num_subscribers = 2
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {:url => "http://rest-test.iron.io/code/202?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)

      queue.reload
      LOG.debug queue
      queue = @client.queue(qname)

      assert_equal num_subscribers, queue.subscribers.size
      assert_equal t, queue.push_type
      puts "queue.push_type: #{queue.push_type}"
      # todo: assert subscriptions match

      msg = "hello #{x}"
      m = queue.post(msg, {:timeout => 2})

      tries = MAX_TRIES
      while tries > 0
        sleep 0.5
        tries -= 1
        subscribers = queue.messages.get(m.id).subscribers
        LOG.debug subscribers
        assert_equal num_subscribers, subscribers.size
        do_retry = false
        subscribers.each do |s|
          LOG.debug s
          do_retry = true unless 202 == s["status_code"]
          do_retry = true unless "reserved" == s["status"]
        end
        next if do_retry
        break
      end
      assert_not_equal tries, 0

      LOG.info 'sleeping 2'
      sleep 2

      tries = MAX_TRIES
      while tries > 0
        sleep 0.5
        subscribers = queue.messages.get(m.id).subscribers
        LOG.debug subscribers
        assert_equal num_subscribers, subscribers.size
        assert_equal t, queue.push_type

        do_retry = false
        subscribers.each do |s|
          LOG.debug s
          LOG.info "status_code=#{s['status_code']}"
          LOG.info "status=#{s['status']}"

          do_retry = true unless 202 == s["status_code"]
          do_retry = true unless "reserved" == s["status"]
        end
        next if do_retry

        # now let's delete it to say we're done with it
        subscribers.each do |s|
          LOG.debug s
          LOG.info "status_code=#{s['status_code']}"
          LOG.info "status=#{s['status']}"
          LOG.info "Acking subscriber"
          res = s.delete
          LOG.debug res
        end
        break
      end
      assert_not_equal 0, tries

      tries = MAX_TRIES
      while tries > 0
        sleep 0.5
        tries -= 1
        subscribers = queue.messages.get(m.id).subscribers
        LOG.debug subscribers
        next unless num_subscribers == subscribers.size

        do_retry = false
        subscribers.each do |s|
          LOG.debug s
          LOG.info "status=#{s['status']}"
          do_retry = true unless "deleted" == s["status"]
        end
        next if do_retry
        break
      end
      assert_not_equal 0, tries

      # delete queue on test complete
      resp = queue.delete_queue
      assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
    end
  end

  def test_post_and_instantiate
    queue = @client.queue('push_and_instantiate')

    subscribers = [{:url => "http://rest-test.iron.io/code/200"},
                   {:url => "http://rest-test.iron.io/code/200"}]

    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => 'multicast')

    expected_size = subscribers.size
    got_size = queue.subscribers.size
    assert_equal expected_size, got_size, "queue's subscribers list must contain #{expected_size} elements, but got #{got_size}"

    msgs = queue.post([{:body => 'push'},
                       {:body => 'me'},
                       {:body => 'now'}], :instantiate => true)
    msgs.each { |msg| assert_instance_of(IronMQ::Message, msg, "post(:instantiate => true) must instantiate messages") }

    sleep 5

    msgs.each do |msg|
      subscr_arr = msg.subscribers
      subscr_arr.each do |s|
        assert_instance_of(IronMQ::Subscriber, s, "message must return `Subscriber`, but got `#{s.class}`")
        rsp = s.delete
        assert_equal 200, rsp.code, "API must response with HTTP 200 status, but returned HTTP #{rsp.code}"
      end
    end

    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end


# tests when converting a push queue back to a pull queue
  def test_converting_types
    queue = @client.queue('converting_queue')
    subscribers = [{:url => "http://rest-test.iron.io/code/200"},
                   {:url => "http://rest-test.iron.io/code/200"}]

    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => 'multicast')
    queue.reload

    assert_equal "multicast", queue.push_type

    p queue.update_queue(:push_type => 'pull')

    queue.reload

    p queue.push_type

    assert_nil queue.push_type

  end

  def test_error_queues
    @rest = Rest::Client.new
    qname = "badrobot"
    error_queue_name = "#{qname}--errors"
    clear_queue(qname)
    clear_queue(error_queue_name)

    x = rand(1000)

    subscribers = []
    subscribers << {:url => "http://rest-test.iron.io/code/503"}
    subscriber_urls = subscribers
    num_subscribers = subscribers.size

    queue = @client.queue(qname)
    res = queue.update_queue(:subscribers => subscribers,
                             :push_type => "multicast",
                             :retries => 3,
                             :retries_delay => 3
    )
    res = queue.update_queue(:error_queue => error_queue_name)

    msg = "hello #{x}"
    puts "Pushing msg: #{msg}"
    m = queue.post(msg)
    orig_id = m.id
    puts "Msg id on post: #{orig_id}"
    LOG.debug m

    tries = MAX_TRIES
    while tries > 0
      puts 'sleeping for 5 to wait for retry'
      sleep 5
      tries -= 1
      subscribers = queue.messages.get(m.id).subscribers
      LOG.debug subscribers
      assert_equal num_subscribers, subscribers.size
      do_retry = false
      subscribers.each do |s|
        LOG.debug s
        if s["url"] == "http://rest-test.iron.io/code/503"
          if "error" == s["status"]
            assert_equal 0, s["retries_remaining"]
          else
            assert_equal 503, s["status_code"]
            do_retry = true
          end
        else
          # this one should error a couple times, then be successful
          LOG.info "retries_remaining: #{s["retries_remaining"]}"
          if ["deleted", "error"].include? s["status"] || 200 == s["status_code"]
            assert_equal 0, s["retries_remaining"]
          else
            do_retry = true
          end
        end
      end
      next if do_retry
      break
    end
    assert_not_equal tries, 0

    # check that the failed messages is in the error queue
    error_queue = @client.queue(error_queue_name)
    em = error_queue.get
    assert_not_nil em
    puts "rawbody: " + em.body
    error_hash = JSON.parse(em.body)
    p error_hash
    assert error_hash['subscribers']
    assert_equal subscriber_urls[0][:url], error_hash['subscribers'][0]['url']
    assert_equal 503, error_hash['code']
    assert_equal orig_id, error_hash['source_msg_id']
    assert_not_nil error_hash['msg']
    em.delete

    # now let's get the original message
    orig_msg = queue.get_message(error_hash['source_msg_id'])
    puts "orig_msg:"
    p orig_msg
    p orig_msg.body
    assert msg, orig_msg.body

    error_queue.delete_queue
    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

end
