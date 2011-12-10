IronMQ Ruby Client
-------------

Getting Started
==============

Install the gem:

    gem install ironmq

Create an IronMQ client object:

    @ironmq = IronMQ::Client.new('token'=>'MYTOKEN', 'project_id'=>'MYPROJECTID')

You can get your `token` and `project_id` at http://www.iron.io .


The Basics
=========

**Push** a message on the queue:

    msg = @ironmq.messages.post("hello world!")
    p msg

**Pop** a message off the queue:

    msg = @ironmq.messages.get()
    p msg

When you pop/get a message from the queue, it will NOT be deleted. It will eventually go back onto the queue after
a timeout if you don't delete it (default timeout is 10 minutes).

**Delete** a message from the queue:

    res = msg.delete # or @ironmq.messages.delete(msg["id"])
    p res

Delete a message from the queue when you're done with it.

Queue Selection
===============

One of the following:

1. Pass `:queue_name=>'my_queue'` into IronMQ::Client.new
1. `@client.queue_name = 'my_queue'`
1. Pass `:queue_name=>'my_queue'` into any post(), get(), or delete()

Queue Information
=================

    queue = @client.queues.get(:name=>@client.queue_name)
    puts "size: #{queue.size}"

 