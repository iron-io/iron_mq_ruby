IronMQ Ruby Client
-------------

Getting Started
==============

Create an IronMQ client object:

    @client = IronMQ::Client.new('token'=>'MYTOKEN', 'project_id'=>'MYPROJECTID')

You can get your `token` and `project_id` at http://www.iron.io .


The Basics
=========

**Push** a message on the queue:

    res = @client.messages.post("hello world!")
    p res

**Pop** a message off the queue:

    res = @client.messages.get()
    p res

When you pop/get a message from the queue, it will NOT be deleted. It will eventually go back onto the queue after
a timeout if you don't delete it (default timeout is 10 minutes).

**Delete** a message from the queue:

    res = @client.messages.delete(res["id"])
    p res

Delete a message from the queue when you're done with it.

Queue Selection
===============

One of the following:

1. Pass `:queue_name=>'my_queue'` into IronMQ::Client.new
1. `@client.queue_name = 'my_queue'`
1. Pass `:queue_name=>'my_queue'` into any post(), get(), or delete()

