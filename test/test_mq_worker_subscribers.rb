# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'
require 'iron_worker_ng'

class TestPushQueues < TestBase

  def setup
    super
  end

  def make_key(i, t, random=0)
    key = "pushq-#{t}-#{i}-#{random}"
  end

=begin
  def test_mq_worker_subscribers

    publisher_name = "publisher"
    receiver_name = "push_receiver"
    code_name = "hello"
    queue = @client.queue(publisher_name)
    receiver_queue = @client.queue(receiver_name)
    clear_queue(receiver_name)

    # test for bad subscribers
    puts "raising..."
    ex = assert_raise do
      # can't subscribe to self
      res = queue.update_queue(:subscribers => [{:url => "ironmq:///#{publisher_name}"}])
    end
    p ex
    ex = assert_raise do
      # must have a token if sending to different project_id
      res = queue.update_queue(:subscribers => [{:url => "ironmq://ABCDEFG@/somerandomqueue"}])
    end
    p ex

    subscribers = []
    subscribers << {:url => "ironmq:///#{receiver_name}"}
    subscribers << {:url => "ironworker:///#{code_name}"}
    # requires a hello worker in your project, run next line to add one:
    # iron_worker upload https://github.com/treeder/hello_worker/blob/master/hello.worker

    res = queue.update_queue(:subscribers => subscribers)

    LOG.debug queue.subscribers
    assert_equal subscribers.size, queue.subscribers.size

    body = "Hello IronMQ pusher!"
    m = queue.post(body)

    sleep 5
    # now check that there's a message in the queue and that the worker got a job
    receiver_queue.reload
    assert_equal 1, receiver_queue.size
    m2 = receiver_queue.get
    assert_equal body, m2.body
    m2.delete


    wc = @config['iron']
    wc[:host] = wc[:worker_host] if wc[:worker_host]
    iron_worker = IronWorkerNG::Client.new(wc)
    tasks = iron_worker.tasks.list(:code_name=>code_name, :from_time=>Time.now - 30)
    assert_equal 1, tasks.size
  end
=end
  
end
