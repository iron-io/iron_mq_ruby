require 'abt'
require 'time'
require 'test_base'

# Config for abt tests to run on IronWorker
@abt_config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "abt", "test", "config.yml")))
IronWorker.configure do |c|
  c.token = @abt_config['iron']['token']
  c.project_id = @abt_config['iron']['project_id']
end

# IronWorker.logger.level = Logger::DEBUG
# Config to run iron_mq_ruby tests
@test_config = TestBase.load_config

worker = Abt::AbtWorker.new
worker.git_url = "git://github.com/iron-io/iron_mq_ruby.git"
worker.test_config = @test_config
worker.add_notifier(:hip_chat_notifier, :config=>@abt_config["hipchat"])
worker.upload # Must upload after adding notifier to ensure it's merged
#worker.run_local
#worker.queue
#status = worker.wait_until_complete
#p status
#puts "LOG:"
#puts worker.get_log
#worker.schedule(:start_at=>Time.now.iso8601, :run_every=>3600)
