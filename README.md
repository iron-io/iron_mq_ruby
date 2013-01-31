IronMQ Ruby Client
-------------

The [full API documentation is here](http://dev.iron.io/mq/reference/api/) and this client tries to stick to the API as
much as possible so if you see an option in the API docs, you can use it in the methods below.

http://dev.iron.io/mq/reference/api/

Getting Started
==============

1\. Install the gem:

    gem install iron_mq

2\. Setup your Iron.io credentials: http://dev.iron.io/mq/reference/configuration/

3\. Create an IronMQ client object:

    @ironmq = IronMQ::Client.new()

Or pass in credentials:

    @ironmq = IronMQ::Client.new(token: MY_TOKEN, project_id: MY_PROJECT_ID)


The Basics
=========

**Get a Queue object**

You can have as many queues as you want, each with their own unique set of messages.

    @queue = @ironmq.queue("my_queue")

Now you can use it:

### Post a message on the queue:

    @queue.post("hello world!")

Post a message with options:

    @queue.post("hello world!", delay: 3600)

### Get a message off the queue:

    msg = @queue.get()
    puts msg.body

Get a message with options:

    msg = @queue.get(timeout: 300)

When you pop/get a message from the queue, it will NOT be deleted. It will eventually go back onto the queue after
a timeout if you don't delete it (default timeout is 60 seconds).

### Delete a message from the queue:

    msg.delete # or @queue.delete(msg.id)

Be sure to delete a message from the queue when you're done with it.

### Poll for messages:

    @queue.poll do |msg|
      puts msg.body
    end

Polling will automatically delete the message at the end of the block.

Queue Information
=================

    queue = @client.queue("my_queue")
    puts "size: #{queue.size}"


Push Queues
===========

IronMQ push queues allow you to setup a queue that will push to an endpoint, rather than having to poll the endpoint. 
[Here's the announcement for an overview](http://blog.iron.io/2013/01/ironmq-push-queues-reliable-message.html). 

### Set subscribers on a queue:

Subscribers can be any http endpoint. push_type is one of:

- multicast - will push to all endpoints/subscribers
- unicast - will push to one and only one endpoint/subscriber


```ruby
subscribers = []
subscribers << {url: "http://rest-test.iron.io/code/200?store=key1"}
subscribers << {url: "http://rest-test.iron.io/code/200?store=key2"}
res = @queue.update_queue(:subscribers => subscribers,
                               :push_type => t)
```

### Add/remove subscribers on a queue

```ruby
@queue.add_subscriber({url: "http://nowhere.com"})
# Or to remove a subscriber:
@queue.remove_subscriber({url: "http://nowhere.com"})
```

### Get message push status

After pushing a message:

```ruby
queue.messages.get(m.id).subscribers
```

Returns an array of subscribers with status.
