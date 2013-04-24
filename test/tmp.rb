gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

  end

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

    assert_equal "pull", queue.push_type

  end


end

