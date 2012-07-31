# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

#$abt_config = {:hello=>'abt_config_ya'}

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

  end

  def test_clear

    q = @client.queue("clearer")

    clear_queue(q.name)

    val = "hi mr clean"
    q.post(val)
    assert q.size == 1

    q.clear
    msg = q.get
    assert msg.nil?

    q.reload

    assert q.size == 0


  end

end