gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TmpTests < TestBase
  def setup
    super

  end


  def test_release
    puts 'test_release'

    queue_name = "test_release_6"
    clear_queue(queue_name)

    msg_txt = "testMessage-"+Time.now.to_s
    # puts msgTxt

    queue = @client.queue(queue_name)

    msg_id = queue.post(msg_txt, {:timeout => 60*5}).id
    # puts "msg_id: #{msg_id}"
    message = queue.get
    # p msg
    assert_equal msg_id, message.id
    # Ok, so should have received same message, now let's release it quicker than the original timeout

    # but first, ensure the next get is nil
    msg = queue.get
    # p msg
    assert_nil msg

    # now release it instantly
    message.release
    msg = queue.get
    # p msg
    assert msg
    assert_equal msg_id, msg.id

    # ok, so should be reserved again
    msgr = queue.get
    # p msgr
    assert_nil msgr

    # let's release it in 10 seconds
    msg.release(:delay => 120)
    msgr = queue.get
    # p msg
    assert_nil msgr

    sleep 121
    msg = queue.get
    assert_not_nil msg
    assert_equal msg_id, msg.id

    msg.release(:delay => 5)
    msg = queue.get
    # p msg
    assert_nil msg

    sleep 6
    msg = queue.get
    assert_not_nil msg
    assert_equal msg_id, msg.id

    # delete queue on test complete
    resp = queue.delete_queue
    assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
  end



end

