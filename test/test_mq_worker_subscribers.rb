# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require File.expand_path('test_base.rb', File.dirname(__FILE__))
require 'logger'

class TestPushQueues < TestBase

  def setup
    super
  end

  def make_key(i, t, random=0)
    key = "pushq-#{t}-#{i}-#{random}"
  end


  def test_mq_worker_subscribers

    qname = "push_receiver"
    code_name = "hello"
    queue = @client.queue(qname)
    subscribers = []
    subscribers << {:url => "ironmq:///#{qname}"}
    subscribers << {:url => "ironworker:///#{code_name}"}
    # requires a hello worker in your project, run next line to add one:
    # > iron_worker upload https://github.com/treeder/hello_worker/blob/master/hello.worker

    res = queue.update_queue(:subscribers => subscribers)

    LOG.debug queue.subscribers
    assert_equal subscribers.size, queue.subscribers.size

    body = "Hello IronMQ pusher!"
    m = queue.post(body)

    sleep 2
    # now check that there's a message in the queue and that the worker got a job
    receiver_queue = @client.queue(qname)
    assert_equal 1, receiver_queue.size
    m2 = receiver_queue.get
    assert_equal m.id, m2.id
    assert_equal body, m2.body
    m2.delete

    iron_worker = IronWorkerNG::Client.new(@client.options)
    tasks = iron_worker.tasks.list(:code_name=>code_name, :from_time=>Time.now - 30)
    assert_equal 1, tasks.size


  end

end
