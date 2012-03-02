# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

#$abt_config = {:hello=>'abt_config_ya'}

gem 'test-unit'
require 'test/unit'
require 'beanstalk-client'
require 'yaml'
require_relative 'test_base'

class IronMQTests < TestBase
  def setup
    super

  end

  def test_beanstalk
    puts 'test_beanstalk'
    config = @config['iron_mq']
    h = "#{config['host']||"mq-aws-us-east-1.iron.io"}:#{config['beanstalkd_port']||11300}"
    puts "beanstalkd url: #{h}"
    beanstalk = Beanstalk::Connection.new(h)
    beanstalk.put("oauth #{config['token']} #{config['project_id']}")
    queue_name = "beanstalk_test"
    clear_queue(queue_name)
    beanstalk.use(queue_name)
    beanstalk.watch(queue_name)

    msg = "hello #{Time.now}"
    beanstalk.put(msg)
    job = beanstalk.reserve
    assert_equal msg, job.body, "body not the same as message."
    job.delete
    job = assert_raise(Beanstalk::TimedOut) {
      beanstalk.reserve(1)
    }

    hasher = {:x => 1, :y => "hello", "yo" => "scooby doo"}
    beanstalk.put(hasher.to_json)
    job = beanstalk.reserve(1)
    got = JSON.parse(job.body)
    assert got.is_a?(Hash)
    assert_equal hasher[:x], got['x']
    job.delete

    msg = "hello there\nthis is a new line"
    beanstalk.put(msg)
    job = beanstalk.reserve(1)
    assert_equal msg, job.body, "#{job.body} does not equal #{msg}"
    job.delete
  end

end
