gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TmpTests < TestBase
  def setup
    super

  end

  def test_error_queues
    @rest = Rest::Client.new
    qname = "badrobot"
    error_queue_name = "#{qname}--errors"

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
    error_hash = JSON.parse(em.body)
    p error_hash
    assert_equal subscriber_urls[0][:url], error_hash['url']
    assert_equal 503, error_hash['code']
    assert_equal orig_id, error_hash['source_msg_id']
    assert_not_nil error_hash['msg']
    assert_not_nil error_hash['msg_id']
  em.delete
    
  # now let's get the original message
  orig_msg = queue.get_message(error_hash['msg_id'])
  puts "orig_msg:"
  p orig_msg.body
  
  error_queue.delete_queue
    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end

end

