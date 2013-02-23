IronMQ Ruby Client
-------------

The [full API documentation is here](http://dev.iron.io/mq/reference/api/) and this client tries to stick to the API as
much as possible so if you see an option in the API docs, you can use it in the methods below.

http://dev.iron.io/mq/reference/api/

#Getting Started

1\. Install the gem:

```ruby
gem install iron_mq
```

2\. Setup your Iron.io credentials: http://dev.iron.io/mq/reference/configuration/

3\. Create an IronMQ client object:

```ruby
ironmq = IronMQ::Client.new
```

Or pass in credentials:

```ruby
ironmq = IronMQ::Client.new(:token => "MY_TOKEN", :project_id => "MY_PROJECT_ID")
```

#The Basics

**Get a Queue object**

You can have as many queues as you want, each with their own unique set of messages.

```ruby
queue = ironmq.queue("my_queue")
```

Now you can use it:

### Post a message on the queue

```ruby
queue.post("hello world!")
```

### Get a message off the queue

```ruby
msg = queue.get
msg.body # => "hello world!"
```

When you pop/get a message from the queue, it will NOT be deleted. It will eventually go back onto the queue after
a `timeout` if you don't delete it (default `timeout` is 60 seconds).

### Delete a message from the queue

```ruby
msg.delete
# or
queue.delete(msg.id)
```

Be sure to delete a message from the queue when you're done with it.

### Retrieve queue information:

```ruby
queue.info # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
queue.id   # => "5127bf043264140e863e2283"
```

#Client

`IronMQ::Client` is based on `IronCore::Client` and provides easy access to the queues and messages.

```ruby
ironmq = IronMQ::Client.new(:token => "MY_TOKEN", :project_id => "MY_PROJECT_ID")
```

### List queues

```ruby
all_queues = ironmq.queues.list # => [#<IronMQ::Queue:...>, ...]
# or
all_queues = ironmq.queues.all  # => [#<IronMQ::Queue:...>, ...]
```

Optional parameters:

* `page`: The 0-based page to view. The default is 0.
* `per_page`: The number of queues to return per page. The default is 30, the maximum is 100.

```ruby
queues = ironmq.queues.all(:page => 1, :per_page => 10)
```

### Get queue by name

```ruby
queue = ironmq.queue "my_queue" # => #<IronMQ::Queue:...>
```

Note: if queue with desired name does not exist it returns fake queue.
Queue will be created automatically on post of first message or queue configuration update.

#Queues

### Retrieve information about queue

```ruby
info = queue.info # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
```

Shortcuts for `queue.info[key]`:

```ruby
id = queue.id # => "5127bf043264140e863e2283"
# Does queue exists on server? Alias for `queue.id.nil?`
is_new = queue.new? # => false

size = queue.size # => 7
name = queue.name # => "my_queue"
overall_messages = queue.total_messages # => 13
subscribers = queue.subscribers # => [{"url" => "http://..."}, ...]

push_type = queue.push_type # => "multicast"
# Does queue Push Queue? Alias for `queue.push_type.nil?`
is_push_queue = queue.push_queue? # => true
```

Note: some info parameters has no shortcuts.

### Delete a Message Queue

```ruby
queue.delete_queue # => #<IronMQ::ResponseBase:...>
```

### Put messages on queue

**Single message:**

```ruby
response = queue.post("something helpful") # => #<IronMQ::ResponseBase:...>
# or
response = queue.post("with parameteres", :timeout => 300) # => #<IronMQ::ResponseBase:...>

message_id = response.id # => "5847899158098068288"
status_message = response.msg # => "Messages put on queue."
http_code = response.code # => 200
```

**Bunch of messages:**
```ruby
# [{:body => VALUE}, ...] format is required for now
messages = [{:body => "first"}, {:body => "second"}]

response = queue.post(messages) # => {"ids" => ["5847899158098068288", ...], "msg" => "Messages put on queue."}
# or
response = queue.post(messages, :timeout => 300) # => {"ids" => ["5847899158098068288", ...], "msg" => "Messages put on queue."}
```


**Optional parameters:**

* `timeout`: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
 Default is 60 seconds. Maximum is 86,400 seconds (24 hours).

* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).

* `expires_in`: How long in seconds to keep the item on the queue before it is deleted.
Default is 604,800 seconds (7 days). Maximum is 2,592,000 seconds (30 days).


### Get messages from queue

```ruby
message = queue.get # => #<IronMQ::Message:...>

# or N messages
messages = queue.get(:n => 7) # => [#<IronMQ::Queue:...>, ...]

# or message by ID
message = queue.get "5127bf043264140e863e2283" # => #<IronMQ::Queue:...>
```

**Optional parameters:**

* `n`: The maximum number of messages to get. Default is 1. Maximum is 100.

* `timeout`: timeout: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
If not set, value from POST is used. Default is 60 seconds, maximum is 86,400 seconds (24 hours).

When `n` parameter is specified and greater than 1 method returns `Array` of `Queue`s.
Otherwise, `Queue` object would be returned.

### Release message

```ruby
message = queue.get => #<IronMQ::Message:...>

response = message.release # => #<IronMQ::ResponseBase:...>
# or
response = message.release(:delay => 42) # => #<IronMQ::ResponseBase:...>
```

**Optional parameters:**

* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).

### Delete a message from a queue

```ruby
message = queue.get # => #<IronMQ::Queue:...>

message.delete # => #<IronMQ::ResponseBase:...>
# or
queue.delete_message(message.id) # => #<IronMQ::ResponseBase:...>
```

### Poll for messages

```ruby
queue.poll { |msg| puts msg.body }
```

Polling will automatically delete the message at the end of the block.

### Clear a queue

```ruby
queue.clear # => #<IronMQ::ResponseBase:...>
```

#Push Queues

IronMQ push queues allow you to setup a queue that will push to an endpoint, rather than having to poll the endpoint. 
[Here's the announcement for an overview](http://blog.iron.io/2013/01/ironmq-push-queues-reliable-message.html). 

### Set subscribers on a queue:

Subscribers can be any HTTP endpoint. `push_type` is one of:

* `multicast`: will push to all endpoints/subscribers
* `unicast`: will push to one and only one endpoint/subscriber

```ruby
ptype = :multicast
subscribers = [
  {url: "http://rest-test.iron.io/code/200?store=key1"}
  {url: "http://rest-test.iron.io/code/200?store=key2"}
]

queue.update(:subscribers => subscribers, :push_type => ptype)
```

### Add/remove subscribers on a queue

```ruby
queue.add_subscriber({url: "http://nowhere.com"})

queue.remove_subscriber({url: "http://nowhere.com"})
```

### Get message push status

After pushing a message:

```ruby
subscr_statuses = queue.messages.get(msg.id).subscribers # => [#<IronMQ::Subscriber:...>, ...]
subscr_statuses.each { |ss| puts "#{ss.id}: #{(ss.code == 200) ? 'Success' : 'Fail'}" }
```

Returns an array of subscribers with status.

### Update a message queue

```ruby
queue_info = queue.update(options) # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
```

**The following parameters are all related to Push Queues:**

* `subscribers`: An array of subscriber hashes containing a “url” field.
This set of subscribers will replace the existing subscribers.
To add or remove subscribers, see the add subscribers endpoint or the remove subscribers endpoint.
See below for example json.

* `push_type`: Either multicast to push to all subscribers or unicast to push to one and only one subscriber. Default is “multicast”.

* `retries`: How many times to retry on failure. Default is 3.

* `retries_delay`: Delay between each retry in seconds. Default is 60.
