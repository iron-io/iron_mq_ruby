# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'
require 'logger'

class TestPushQueues < TestBase

  def setup
    super
    @skip = @host.include? 'rackspace'
    return if @skip # bypass these tests if rackspace
  end

  def make_key(i, t, random=0)
    key = "pushq-#{t}-#{i}-#{random}"
  end


  def test_queue_subscriptions
    omit_if @skip
    types = ["multicast", "unicast"]
    types.each do |t|

      LOG.info "Trying type #{t}"

      qname = "subscription-queue-#{t}"

      num_subscribers = 10
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {url: "http://rest-test.iron.io/code/200?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)
      queue = @client.queue(qname)
      LOG.debug queue
      LOG.debug queue.subscribers
      assert_equal num_subscribers, queue.subscribers.size

      # add the last one
      queue.reload # temporary, can remove
      queue.add_subscriber({url: "http://nowhere.com"})
      queue.reload
      assert_equal num_subscribers + 1, queue.subscribers.size
      queue.remove_subscriber({url: "http://nowhere.com"})
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
          assert_not_equal tries, 0
        end
      elsif t == "unicast"
        tries = MAX_TRIES
        while tries > 0
          tries -= 1
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
        tries -= 1
        subscribers = queue.messages.get(m.id).subscribers
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
    end
  end


  def test_failure
    omit_if @skip
    @rest = Rest::Client.new
    qname = "failure-queue"

    x = rand(1000)

    subscribers = []
    subscribers << {url: "http://rest-test.iron.io/code/503?switch_after=2&switch_to=200&namespace=push-test-failures-#{x}"}
    subscribers << {url: "http://rest-test.iron.io/code/503"}

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
      tries -= 1
      subscribers = queue.messages.get(m.id).subscribers
      LOG.debug subscribers
      assert_equal num_subscribers, subscribers.size
      do_retry = false
      subscribers.each do |s|
        LOG.debug s
        if s["url"] == "http://rest-test.iron.io/code/503"
          do_retry = true unless 503 == s["status_code"]
          do_retry = true unless "error" == s["status"]
        else
          do_retry = true unless 200 == s["status_code"]
          do_retry = true unless "deleted" == s["status"]
        end
      end
      next if do_retry
      break
    end
    assert_not_equal tries, 0
  end


  def test_202
    omit_if @skip
    types = ["multicast"]
    types.each do |t|

      LOG.info "Trying type #{t}"

      qname = "subscription-queue-#{t}-202"

      num_subscribers = 2
      subscribers = []

      x = rand(1000)
      num_subscribers.times do |i|
        key = make_key(i, t, x)
        subscribers << {url: "http://rest-test.iron.io/code/202?store=#{key}"}
      end

      queue = @client.queue(qname)
      res = queue.update_queue(:subscribers => subscribers,
                               :push_type => t)
      queue = @client.queue(qname)
      LOG.debug queue
      LOG.debug queue.subscribers
      assert_equal num_subscribers, queue.subscribers.size
      # todo: assert subscriptions match

      msg = "hello #{x}"
      m = queue.post(msg, 
                     {:timeout => 2})

      tries = MAX_TRIES
      while tries > 0
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
        subscribers = queue.messages.get(m.id).subscribers
        LOG.debug subscribers
        assert_equal num_subscribers, subscribers.size

        do_retry = false
        subscribers.each do |s|
          LOG.debug s
          LOG.info "status_code=#{s['status_code']}"
          LOG.info "status=#{s['status']}"

          do_retry = true unless 202 == s["status_code"]
          do_retry = true unless "reserved" == s["status"]

          # now let's delete it to say we're done with it
          LOG.info "Acking subscriber"
          res = s.delete
          LOG.debug res
        end
        next if do_retry
        break
      end
      assert_not_equal 0, tries

      tries = MAX_TRIES
      while tries > 0
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
    end
  end


  def test_202_failure
    omit_if @skip
  end

end
