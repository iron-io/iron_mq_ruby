IronMQ Ruby Client
-------------

The [full API documentation is here](http://dev.iron.io/mq/reference/api/) and this client tries to stick to the API as
much as possible so if you see an option in the API docs, you can use it in the methods below.

**WARNING: Version 5+ has some small breaking changes. Version 4 ignored 404's on delete operations, Version
5 will now raise exceptions.

## Getting Started

1\. Install the gem:

```ruby
gem install iron_mq
```

2\. [Setup your Iron.io credentials](http://dev.iron.io/mq/reference/configuration/)

3\. Create an IronMQ client object:

```ruby
ironmq = IronMQ::Client.new
```

Or pass in credentials if you don't want to use an iron.json file or set ENV variables:

```ruby
ironmq = IronMQ::Client.new(:token => "MY_TOKEN", :project_id => "MY_PROJECT_ID")
```
You can also change the host if you want to use a different cloud or region, for example, to use Rackspace ORD:

```ruby
ironmq = IronMQ::Client.new(:host => "mq-rackspace-ord.iron.io", :token => "MY_TOKEN", :project_id => "MY_PROJECT_ID")
```
The default host is AWS us-east-1 zone (mq-aws-us-east-1.iron.io). [See all available hosts/clouds/regions](http://dev.iron.io/mq/reference/clouds/).

## The Basics

### Get Queues List

```ruby
queues = ironmq.list_queues # => [#<IronMQ::Queue:...>, ...]
```

--

### Get a Queue Object

You can have as many queues as you want, each with their own unique set of messages.

```ruby
queue = ironmq.queue("my_queue")
```

Now you can use it.

--

### Post a Message on a Queue

Messages are placed on the queue in a FIFO arrangement.
If a queue does not exist, it will be created upon the first posting of a message.

```ruby
queue.post("hello world!")
```

--

### Retrieve Queue Information

```ruby
queue.info # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
queue.id   # => "5127bf043264140e863e2283"
```

--

### Get a Message off a Queue

```ruby
msg = queue.get
msg.body # => "hello world!"
```

When you pop/get a message from the queue, it is no longer on the queue but it still exists within the system.
You have to explicitly delete the message or else it will go back onto the queue after the `timeout`.
The default `timeout` is 60 seconds. Minimal `timeout` is 30 seconds.

--

### Delete a Message from a Queue

```ruby
msg.delete
# or
queue.delete(msg.id)
```

Be sure to delete a message from the queue when you're done with it.

--


## Client

`IronMQ::Client` is based on `IronCore::Client` and provides easy access to the queues.

```ruby
ironmq = IronMQ::Client.new(:token => "MY_TOKEN", :project_id => "MY_PROJECT_ID")
```

### List Queues

```ruby
all_queues = ironmq.queues.list # => [#<IronMQ::Queue:...>, ...]
# or
all_queues = ironmq.queues.all  # => [#<IronMQ::Queue:...>, ...]
```

**Optional parameters:**

* `page`: The 0-based page to view. The default is 0.
* `per_page`: The number of queues to return per page. The default is 30, the maximum is 100.
* `raw`: Set it to true to obtain data in raw format. The default is false.

```ruby
queues = ironmq.queues.all(:page => 1, :per_page => 10)
```

--

### Get Queue by Name

```ruby
queue = ironmq.queue "my_queue" # => #<IronMQ::Queue:...>
```

**Note:** if queue with desired name does not exist it returns fake queue.
Queue will be created automatically on post of first message or queue configuration update.

--

## Queues

### Retrieve Queue Information

```ruby
info = queue.info # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
```

Shortcuts for `queue.info[key]`:

```ruby
id = queue.id # => "5127bf043264140e863e2283"

size = queue.size # => 7
name = queue.name # => "my_queue"
overall_messages = queue.total_messages # => 13
subscribers = queue.subscribers # => [{"url" => "http://..."}, ...]

push_type = queue.push_type # => "multicast"
# Does queue Push Queue? Alias for `queue.push_type.nil?`
is_push_queue = queue.push_queue? # => true
```

**Warning:** to be sure configuration information is up-to-date
client library call IronMQ API each time you request for any parameter except `queue.name`.
In this case you may prefer to use `queue.info` to have `Hash` with all available info parameters.

--

### Delete a Message Queue

```ruby
response = queue.delete_queue # => #<IronMQ::ResponseBase:...>
```

--

### Post Messages to a Queue

**Single message:**

```ruby
response = queue.post("something helpful") # => #<IronMQ::ResponseBase:...>
# or
response = queue.post("with parameteres", :timeout => 300) # => #<IronMQ::ResponseBase:...>

message_id = response.id # => "5847899158098068288"
status_message = response.msg # => "Messages put on queue."
http_code = response.code # => 200
```

**Multiple messages:**
```ruby
# [{:body => VALUE}, ...] format is required
messages = [{:body => "first"}, {:body => "second"}]

response = queue.post(messages) # => {"ids" => ["5847899158098068288", ...], "msg" => "Messages put on queue."}
# or
response = queue.post(messages, :timeout => 300) # => {"ids" => ["5847899158098068288", ...], "msg" => "Messages put on queue."}
```

**Optional parameters:**

* `timeout`: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
 Default is 60 seconds. Minimum is 30 seconds. Maximum is 86,400 seconds (24 hours).

* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).

* `expires_in`: How long in seconds to keep the item on the queue before it is deleted.
Default is 604,800 seconds (7 days). Maximum is 2,592,000 seconds (30 days).

--

### Get Messages from a Queue

```ruby
message = queue.get # => #<IronMQ::Message:...>

# or N messages
messages = queue.get(:n => 7) # => [#<IronMQ::Message:...>, ...]

# or message by ID
message = queue.get "5127bf043264140e863e2283" # => #<IronMQ::Message:...>
```

**Optional parameters:**

* `n`: The maximum number of messages to get. Default is 1. Maximum is 100.
* `timeout`: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
If not set, value from POST is used. Default is 60 seconds. Minimum is 30 seconds.
Maximum is 86,400 seconds (24 hours).
* `wait`: : Time in seconds to wait for a message to become available. This enables long polling. Default is 0 (does not wait), maximum is 30.
* `delete`: true/false. This will delete the message on get. Be careful though, only use this if you are ok with losing a message if something goes wrong after you get it. Default is false.

When `n` parameter is specified and greater than 1 method returns `Array` of `Message`s.
Otherwise, `Message` object would be returned.

--

### Touch a Message on a Queue

Touching a reserved message extends its timeout by the duration specified when the message was created, which is 60 seconds by default.

```ruby
message = queue.get # => #<IronMQ::Message:...>

message.touch # => #<IronMQ::ResponseBase:...>
```

--

### Release Message

```ruby
message = queue.get # => #<IronMQ::Message:...>

response = message.release # => #<IronMQ::ResponseBase:...>
# or
response = message.release(:delay => 42) # => #<IronMQ::ResponseBase:...>
```

**Optional parameters:**

* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).

--

### Delete a Message from a Queue

```ruby
message = queue.get # => #<IronMQ::Queue:...>

message.delete # => #<IronMQ::ResponseBase:...>
```

--

### Peek Messages from a Queue

Peeking at a queue returns the next messages on the queue, but it does not reserve them.

```ruby
message = queue.peek # => #<IronMQ::Message:...>
# or multiple messages
messages = queue.peek(:n => 13) # => [#<IronMQ::Message:...>, ...]
```

**Optional parameters:**

* `n`: The maximum number of messages to peek. Default is 1. Maximum is 100.

--

### Poll for Messages

```ruby
queue.poll { |msg| puts msg.body }
```

Polling will automatically delete the message at the end of the block.

--

### Clear a Queue

```ruby
queue.clear # => #<IronMQ::ResponseBase:...>
```
### Add an Alert to a Queue

[Check out our Blog Post on Queue Alerts](http://blog.iron.io).

Alerts have now been incorporated into IronMQ. This feature lets developers control actions based on the activity within a queue. With alerts, actions can be triggered when the number of messages in a queue reach a certain threshold. These actions can include things like auto-scaling, failure detection, load-monitoring, and system health.

You may add up to 5 alerts per queue.

**Required parameters:**
* `type`: required - "fixed" or "progressive". In case of alert's type set to "fixed", alert will be triggered when queue size pass value set by trigger parameter. When type set to "progressive", alert will be triggered when queue size pass any of values, calculated by trigger * N where N >= 1. For example, if trigger set to 10, alert will be triggered at queue sizes 10, 20, 30, etc.
* `direction`: required - "asc" or "desc". Set direction in which queue size must be changed when pass trigger value. If direction set to "asc" queue size must growing to trigger alert. When direction is "desc" queue size must decreasing to trigger alert.
* `trigger`: required. It will be used to calculate actual values of queue size when alert must be triggered. See type field description. Trigger must be integer value greater than 0.
* `queue`: required. Name of queue which will be used to post alert messages.

**Optional parameters:**

* `snooze`: Number of seconds between alerts. If alert must be triggered but snooze is still active, alert will be omitted. Snooze must be integer value greater than or equal to 0.

```ruby
queue.add_alert({:type => "progressive",
                  :trigger => 10,
                  :queue => "my_alert_queue",
                  :direction => "asc",
                  :snooze => 0
                 })
queue.clear #  => #<IronMQ::ResponseBase:0x007f95d3b25438 @raw={"msg"=>"Updated"}, @code=200>
```



--


## Push Queues

IronMQ push queues allow you to setup a queue that will push to an endpoint, rather than having to poll the endpoint. 
[Here's the announcement for an overview](http://blog.iron.io/2013/01/ironmq-push-queues-reliable-message.html). 

### Update a Message Queue

```ruby
queue_info = queue.update(options) # => {"id"=>"5127bf043264140e863e2283", "name"=>"my_queue", ...}
```

**The following parameters are all related to Push Queues:**

* `subscribers`: An array of subscriber hashes containing a “url” field.
This set of subscribers will replace the existing subscribers.
To add or remove subscribers, see the add subscribers endpoint or the remove subscribers endpoint.
See below for example json.
* `push_type`: Either `multicast` to push to all subscribers or `unicast` to push to one and only one subscriber. Default is `multicast`.
* `retries`: How many times to retry on failure. Default is 3. Maximum is 100.
* `retries_delay`: Delay between each retry in seconds. Default is 60.

--

### Set Subscribers on a Queue

Subscribers can be any HTTP endpoint. `push_type` is one of:

* `multicast`: will push to all endpoints/subscribers
* `unicast`: will push to one and only one endpoint/subscriber

```ruby
ptype = :multicast
subscribers = [
  {:url => "http://rest-test.iron.io/code/200?store=key1"},
  {:url => "http://rest-test.iron.io/code/200?store=key2"}
]

queue.update(:subscribers => subscribers, :push_type => ptype)
```

--

### Add/Remove Subscribers on a Queue

```ruby
queue.add_subscriber({:url => "http://nowhere.com"})

queue.add_subscribers([
  {:url => 'http://first.endpoint.xx/process'},
  {:url => 'http://second.endpoint.xx/process'}
])


queue.remove_subscriber({url: "http://nowhere.com"})

queue.remove_subscribers([
  {:url => 'http://first.endpoint.xx/process'},
  {:url => 'http://second.endpoint.xx/process'}
])
```

--

### Post and instantiate

Sometimes you may want to post message to the Push Queue and instantiate `Message`
instead getting it by ID returned in API response. To do this just set `:instantiate`
to `true`.

```ruby
message = queue.post('push me!', :instantiate => true) # => #<IronMQ::Message:...>

msgs = queue([{:body => 'push'}, {:body => 'me'}], :instantiate => true) # => [#<IronMQ::Message:...>, ...]
```

This creates fake `Message` objects. They contain only IDs.

--

### Get Message Push Status

After pushing a message:

```ruby
subscribers = queue.get(msg.id).subscribers # => [#<IronMQ::Subscriber:...>, ...]

subscribers.each { |ss| puts "#{ss.id}: #{(ss.code == 200) ? 'Success' : 'Fail'}" }
```

Returns an array of subscribers with status.

**Note:** getting a message by ID is only for usable for Push Queues.
This creates fake `IronMQ::Message` instance on which you call for subscribers' push statuses.

--

### Acknowledge / Delete Push Message for a Subscriber

```ruby
subscribers = queue.get(msg.id).subscribers # => [#<IronMQ::Subscriber:...>, ...]

subscribers.each do |ss|
  ss.delete
  # ss.acknowledge # This is `delete` alias
end
```

--

### Revert Queue Back to Pull Queue

If you want to revert you queue just update `push_type` to `'pull'`.

```ruby
queue.update(:push_type => 'pull');
```

--

## Queue Alerts

Queue Alerts allow you to set queue's size levels which are critical
for your application. For example, you want to start processing worker
when queue size grows from 0 to 1. Then add alert of `type` "fixed",
`direction` "asc", and `trigger` 1. In this case, if queue size changed
from 0 to 1 alert message will be put on queue, set by `queue`
parameter of alert's hash. If you want to prevent alerts to be put onto
alert queue in some time after previous alert message - use `snooze`
parameter. For example, to make alert silent in one hour, set `snooze`
to 3600 (seconds).

**Note:** alerts feature are only avalable for Pull (or regular) Queues.

See [Queue Alerts](http://dev.iron.io/mq/reference/queue_alerts/) to learn more.

### Alerts Parameters

Alerts can be configured with the following parameters:

* `type`: string, required. Type of alert. Available types are "fixed"
  and "progressive".
* `direction`: string, optional. Direction of queue fluctuations.
  Available directions are "asc" (alert will be triggered if queue
  size grows) and "desc" (alert will be triggered if queue size
  decreases). Defaults to "asc".
* `trigger`: integer, required. Value which is used to calculate
  actual queue size when alert will be triggered. In case of "fixed"
  type of alert `trigger` itself represents actual queue size. When
  type of alert is "progressive", actual queue sizes are calculated by
  `trigger * N`, where `N` is integer greater than 0. For example,
  type is "progressive" and trigger is 100. Alert messages will be put
  on queue at sizes 100, 200, 300, ...
* `queue`: string, required. Name of a queue which receives alert messages.
* `snooze`: integer, optional. Represents number of seconds alert will
  be silent after latter message, put onto alert queue.

**Note:** IronMQ backend checks for alerts duplications each time you
  add new alerts to a queue. It compares `type`, `direction`, and
  `trigger` parameters to find duplicates. If one or more of new
  alerts duplicates existing, backend return `HTTP 400` error, message
  will be `{"msg": "At least one new alert duplicates current queue alerts."}`.

### Add Alerts to a Queue

To add single alert to a queue.

```ruby
queue.add_alert({
  :type => 'fixed',
  :direction => 'asc',
  :trigger => 1,
  :queue => 'alerts-queue',
  :snooze => 600
})
# => #<IronMQ::ResponseBase:0x007f8d22980420 @raw={"msg"=>"Alerts were added."}, @code=200>
```

To add multiple alerts at a time.

```ruby
queue.add_alerts([
  {
    :type => 'fixed',
    :direction => 'desc',
    :trigger => 1,
    :queue => 'alerts-queue'
  },
  {
    :type => "progressive",
    :trigger => 1000,
    :queue => 'critical-alerts-queue'
  }
])
# => #<IronMQ::ResponseBase:0x00abcdf1980420 @raw={"msg"=>"Alerts were added."}, @code=200>
```

### Remove Alerts from a Queue

To remove single alert by its ID.

```ruby
queue.remove_alert({ :id => '5eee546df4a4140e8638a7e5' })
# => #<IronMQ::ResponseBase:0x007f8d229a1878 @raw={"msg"=>"Alerts were deleted."}, @code=200>
```

Remove multiple alerts by IDs.

```ruby
queue.remove_alerts([
  { :id => '53060b541185ab3eaf04c83f' },
  { :id => '99a50b541185ab3eaf9bcfff' }
])
# => #<IronMQ::ResponseBase:0x093b8d229a18af @raw={"msg"=>"Alerts were deleted."}, @code=200>
```

### Replace and Clear Alerts on a Queue

Following code sample shows how to replace alerts on a queue.

```ruby
queue.replace_alerts([
  {
    :type => 'fixed',
    :trigger => 100,
    :queue => 'alerts'
  }
])
# => #<IronMQ::ResponseBase:0x00008d229a16bf @raw={"msg"=>"Alerts were replaced."}, @code=200>
```

To clear alerts on a queue.

```ruby
queue.clear_alerts
# => #<IronMQ::ResponseBase:0x87ad13ff3a18af @raw={"msg"=>"Alerts were replaced."}, @code=200>
```

**Note:** `Queue#clear_alerts` is a helper, which represents
  `Queue#replace_alerts` call with empty `Array` of alerts.

## Further Links

* [IronMQ Overview](http://dev.iron.io/mq/)
* [IronMQ REST/HTTP API](http://dev.iron.io/mq/reference/api/)
* [Push Queues](http://dev.iron.io/mq/reference/push_queues/)
* [Other Client Libraries](http://dev.iron.io/mq/libraries/)
* [Live Chat, Support & Fun](http://get.iron.io/chat)

-------------
© 2011 - 2013 Iron.io Inc. All Rights Reserved.
