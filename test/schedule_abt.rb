require 'abt'
require_relative 'test_base'

# Config for abt tests to run on IronWorker
@abt_config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "abt", "test", "config.yml")))
IronWorker.configure do |c|
  c.token = @abt_config['iron']['token']
  c.project_id = @abt_config['iron']['project_id']
end

# Config to run iron_mq_ruby tests
@test_config = TestBase.load_config

worker = Abt::AbtWorker.new
worker.git_url = "git://github.com/iron-io/iron_mq_ruby.git"
worker.test_config = @test_config
worker.add_notifier(:hip_chat_notifier, :config=>@abt_config["hipchat"])
#worker.add_notifier(File.join(File.dirname(__FILE__), 'console_notifier'), :class_name=>'ConsoleNotifier')
#worker.add_notifier("WebHookNotifier", "url"=>"http://www.someurl.com")
#worker.run_local
worker.queue
status = worker.wait_until_complete
p status
puts "LOG:"
puts worker.get_log

