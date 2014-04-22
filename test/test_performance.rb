gem 'test-unit'
require 'test/unit'
require 'yaml'
require 'parallel'
require_relative 'test_base'

class TmpTests < TestBase
  def setup
    super

  end

  def test_performance_post_100_messages
    queue = @client.queue('test_perf_100')
    # slower to rackspace since this is running on aws
    timeout = @host.include?('rackspace') ? 40 : 12

    assert_performance(timeout) do
      100.times do
        queue.post("hello world!")
      end

      # delete queue on test complete
      resp = queue.delete_queue
      assert_equal 200, resp.code, "API must response with HTTP 200 status, but returned HTTP #{resp.code}"
    end
  end
end

