gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super
  end

  def test_x()
    list = @client.queues
    p list
  end


end
