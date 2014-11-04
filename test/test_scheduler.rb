# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'

class TestScheduler < TestBase

  def setup
    super
  end

  def test_scheduler
    # Make schedule
    name = "My Schedule"
    schedmap = {
        url: "http://requestb.in/15s04qf1",
        timezone: "",
        schedule: "every 1 minute"
    }
    @client.schedule_create(name, schedmap)

    # Check schedule exists and matches
    schedule = @client.schedule_get(name)
    p schedule
    schedmap.each_pair do |k, v|
      assert_equal schedmap[k], schedule[k.to_s]
    end

    schedules = @client.schedules_list
    puts "schedules=" + schedules.inspect
    found = false
    schedules.each do |s|
      if s.name == name
        found = true
        schedmap.each_pair do |k, v|
          assert_equal schedmap[k], s[k.to_s]
        end
      end
    end
    assert found

    # Verify that it's pushing to an endpoint on the schedule
    # todo

    sleep 130

    @client.schedule_delete(name)
    assert_nil @client.schedule_get(name)

  end

end
