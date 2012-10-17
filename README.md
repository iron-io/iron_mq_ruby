
IronMQ Ruby Client
-------------

Getting Started
==============

1\. Install the gem:

    gem install iron_mq

2\. Setup your Iron.io credentials: http://dev.iron.io/articles/configuration/

3\. Create an IronMQ client object:

    @ironmq = IronMQ::Client.new()


The Basics
=========

**Get a Queue object**

You can have as many queues as you want, each with their own unique set of messages.

    @queue = @ironmq.queue("my_queue")

Now you can use it:

**Post** a message on the queue:

    @queue.post("hello world!")

**Get** a message off the queue:

    msg = @queue.get()
    puts msg.body

When you pop/get a message from the queue, it will NOT be deleted. It will eventually go back onto the queue after
a timeout if you don't delete it (default timeout is 10 minutes).

**Delete** a message from the queue:

    msg.delete # or @queue.delete(msg.id)

Be sure to delete a message from the queue when you're done with it.

**Poll** for messages:

    @queue.poll do |msg|
      puts msg.body
    end

Polling will automatically delete the message at the end of the block.

Queue Information
=================

    queue = @client.queue("my_queue")
    puts "size: #{queue.size}"

