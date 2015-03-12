IronMQ Ruby Client
-------------

The [full API v3 documentation is here](http://dev.iron.io/mq/3/reference/api/) and this client tries to stick to the API as
much as possible so if you see an option in the API docs, you can use it in the methods below.

**WARNING:** Version 6 is compatible only with IronMQ v3 API. All backward compatibility code is removed.

[Important Notes](#important-notes).

## Getting Started

1\. Install the gem:

<!---

```ruby
gem install iron_mq
```
-->

We don't have v3 in rubygems yet, but you can use Bundler to easily use this gem. Add this to your Gemfile:

```ruby
gem 'iron_mq', git: 'https://github.com/iron-io/iron_mq_ruby.git', branch: 'v3'
```

Then do a `bundle update` and when executing, be sure to use `bundle exec` like so:

```
bundle exec ruby script.rb
```

2\. [Setup your Iron.io credentials](http://dev.iron.io/mq/reference/configuration/)

3\. Create an IronMQ client object:

```ruby
ironmq = IronMQ::Client.new
```

Or pass in credentials if you don't want to use an iron.json file or set ENV variables:

```ruby
ironmq = IronMQ::Client.new(token: 'MY_TOKEN', project_id: 'MY_PROJECT_ID')
```
You can also change the host if you want to use a different cloud or region, for example, to use Rackspace ORD:

```ruby
ironmq = IronMQ::Client.new(host: 'mq-rackspace-ord.iron.io',
                            token:'MY_TOKEN',
                            project_id: 'MY_PROJECT_ID')
```
The default host is AWS us-east-1 zone (mq-aws-us-east-1-1.iron.io). [See all available hosts/clouds/regions](http://dev.iron.io/mq/reference/clouds/).

### Keystone Authentication

#### Via Configuration File

Add `keystone` section to your iron.json file:

```javascript
{
  "project_id": "57a7b7b35e8e331d45000001",
  "keystone": {
    "server": "http://your.keystone.host/v2.0/",
    "tenant": "some-group",
    "username": "name",
    "password": "password"
  }
}
```

#### In Code

```ruby
keystone = {
  server: "http://your.keystone.host/v2.0/",
  tenant: "some-gorup",
  username: "name",
  password: "password"
}
client = IronMQ::Client.new(project_id: "57a7b7b35e8e331d45000001", keystone: keystone)
```

## The Basics

### Get Queues List

```ruby
queues = ironmq.get_queues # => [#<IronMQ::Queue:...>, ...]
# alias:
#   Client#queues
```

--

### Make a Queue Object

You can have as many queues as you want, each with their own unique set of messages.

```ruby
# pass queue name
queue = ironmq.make_queue('my_queue') # => #<IronMQ::Queue:...>
# alias:
#   Client#queue
```

Now you can use it.

--

### Post a Message on a Queue

Messages are placed on the queue in a FIFO arrangement.
If a queue does not exist, it will be created upon the first posting of a message.

```ruby
response = queue.post_messages('hello world!') # => {"ids" => ["1234567890"]}
# alias:
#   Queue#post
```

--

### Retrieve Queue Information

```ruby
# currently contained by Queue instance
queue.get_info # => {name: "my_queue", ...}
# alias:
#   Queue#info

# load via IronMQ API, Queue instance will be updated in-place
queue.get_info! # => {"queue" => {"name" => "my_queue", ...}}
# alias:
#   Queue#info!
```

--

### Reserve/Get a Message from a Queue

```ruby
msgs = queue.reserve_messages(n: 5) # => [#<IronMQ::Message:...>, ...]
# alias:
#   Queue#reserve
# singular version:
#   Queue#reserve_message
```

When you reserve a message from the queue, it is no longer on the queue but it still exists within the system.
You have to explicitly delete the message or else it will go back onto the queue after the `timeout`.
The default `timeout` is 60 seconds. Minimal `timeout` is 30 seconds.

--

### Delete a Message from a Queue

```ruby
msg.delete! # => {"msg" => "Deleted"}
# or
queue.delete_message(msg) # => {"msg" => "Deleted"}
# plural version:
#   Queue#delete_messages
```

Be sure to delete a message from the queue when you're done with it.

```ruby
messages = queue.reserve(n: 3)
queue.delete_messages(messages) # => {"msg" => "Deleted"}
```

Delete reserved messages when you're done with it.

--

## Usage

`IronMQ::Client` is based on `IronCore::Client` and provides easy access to the queues.

```ruby
ironmq = IronMQ::Client.new(token: 'MY_TOKEN', project_id: 'MY_PROJECT_ID')
```

### List Queues

```ruby
queues = ironmq.get_queues # => [#<IronMQ::Queue:...>, ...]
# alias:
#   Client#queues
```

**Optional parameters:**

* `per_page`: number of elements in response, default is 30.
* `previous`: this is the last queue on the previous page, it will start from the next one. If queue with specified
               name doesn’t exist result will contain first per_page queues that lexicographically greater than previous
* `prefix`: an optional queue prefix to search on. e.g., prefix=ca could return queues `["cars", "cats", etc.]`
* `raw`: Set it to true to obtain data in raw format. The default is false.

```ruby
queues = ironmq.queues(per_page: 10, previous: 'test_queue')
# => [#<IronMQ::Queue:...>, ...]
```

--

### Get Queue

#### Make an Instance of Queue Class

```ruby
# create an instance of Queue class with queue name
queue = ironmq.make_queue('test-queue') # => #<IronMQ::Queue:...>
# alias:
#   Client.queue

# with queue info hash
queue = ironmq.queue(name: 'test-queue') # => #<IronMQ::Queue:...>
```

#### Get a Queue by API Call

```ruby
queue = ironmq.get_queue('my_queue') # => #<IronMQ::Queue:...>
```

**Note:** if queue does not exist, `Rest::HttpError` will be raised.

--

### Create a Queue

```ruby
queue = ironmq.create_queue('my-queue') # => #<IronMQ::Queue:...>
# or with options
queue = ironmq.create_queue('my-queue', message_timeout: 180)
# => #<IronMQ::Queue:...>

# or with instance of Queue class
queue = IronMQ::Queue.new(ironmq, 'my-queue')
queue.create!(type: 'pull', message_timeout: 600)
# => {"queue" => {"name" => "my-queue", ...}}
```

**Options:**

* `type`: String or symbol. Queue type. `:pull`, `:multicast`, `:unicast`. Field required and static.
* `message_timeout`: Integer. Number of seconds before message back to queue if it will not be deleted or touched.
* `message_expiration`: Integer. Number of seconds between message post to queue and before message will be expired.

**Push queues only:**

* `push: subscribers`: An array of subscriber hashes containing a `name` and a `url` required fields,
and optional `headers` hash. `headers`'s keys are names and values are means of HTTP headers.
This set of subscribers will replace the existing subscribers.
To add or remove subscribers, see the add subscribers endpoint or the remove subscribers endpoint.
See below for example json.
* `push: retries`: How many times to retry on failure. Default is 3. Maximum is 100.
* `push: retries_delay`: Delay between each retry in seconds. Default is 60.
* `push: error_queue`: String. Queue name to post push errors to.

--

### Update a Queue

```ruby
queue = ironmq.update_queue('my-queue', message_timeout: 300) # => #<IronMQ::Queue:...>
# or
queue.update!(message_timeout: 600) # => {"queue" => {"name": "my-queue", ...}}
```

--

### Delete a Queue

```ruby
response = ironmq.delete_queue('my-queue') # => {"msg" => "Deleted"}
# or
queue.delete! # => {"msg" => "Deleted"}
```

--

### Retrieve Queue Information

#### From an Instance of Queue Class

```ruby
info = queue.get_info # => {name: "my-queue", ...}
# alias:
#   Queue#info
```

Methods to access queue fields:

```ruby
queue.name # => "my-queue"
queue.project_id # => "1234567890"
queue.type # => "pull"
queue.size # => 7
queue.total_messages # => 13
queue.message_timeout # => 600
queue.message_expiration # => 123456
queue.alerts # => [{name: "alert-1", ...}, ...]
queue.push # => {retries: 3, subscribers: [...], ...}
# alias:
#   Queue#push_info

# some helpers
queue.push_queue? # => true
queue.subscribers # => [{name: "sub-name", url: "http://..."}, ...]
```

#### Retrieve Information From the API

This method retrieves information from the IronMQ API and patches instance in-place.

```ruby
response = queue.get_info! # => {"queue" => {"name" => "my-queue", ...}}
# alias:
#   Queue#info!
```

--

### Manage Alerts of a Queue

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

#### Add Alerts

```ruby
queue.add_alerts([{name: 'alert-on-ten'
                   type: 'progressive',
                   trigger: 10,
                   queue: 'my-alert-queue',
                   direction: 'asc',
                   snooze: 0}])
# singular method:
#   Queue#add_alert
#
# reload info after adding alerts (makes additional call)
#   Queue#add_alerts!
#   Queue#add_alert!
```

#### Remove Alerts

```ruby
queue.remove_alerts([{name: 'alert-on-ten'}])
# singular method:
#   Queue#remove_alert
#
# reload info after removing alerts (makes additional call)
#   Queue#remove_alerts!
#   Queue#remove_alert!
```

#### Replace Alerts

```ruby
queue.replace_alerts([{name: 'alert-on-one',
                       type: 'fixed',
                       trigger: 1,
                       queue: 'non-empty-alert',
                       direction: 'asc'}])
# reload info after removing alerts (makes additional call)
#   Queue#replace_alerts!
```

#### Clear Alerts

```ruby
queue.clear_alerts
# reload info after removing alerts (makes additional call)
#   Queue#clear_alerts!
# NOTE: this is helper method, which calls:
#   Queue#replace_alerts([])
```

--

### Post Messages to a Queue

**Single message:**

```ruby
response = queue.post_message('something helpful') # => {"ids" => ["1234567890"]}
# or
response = queue.post_message('with parameteres', timeout: 300)
# => {"ids" => ["1234567890"]}

# instantiate message
msg = queue.post_message('my-message', instantiate: true)
msg.id # => "1234567890"
msg.body # => "my-message"
```

**Multiple messages:**
```ruby
# [{body: VALUE, ...}, ...] format is required
messages = [{body: 'first'}, {body: 'second'}]
response = queue.post_messages(messages)
# => {"ids" => ["5847899158098068288", ...]}
# or
response = queue.post_messages(messages, timeout: 300)
# => {"ids" => ["5847899158098068288", ...]}

# instantiate messages
msgs = queue.post_messages(messages, timeout: 300, instantiate: true)
# => [#<IronMQ::Message:...>, ...]

# alias:
#   Queue.post
```

**Optional parameters:**

* `timeout`: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
Default is 60 seconds. Minimum is 30 seconds. Maximum is 86,400 seconds (24 hours).
* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).
* `expires_in`: How long in seconds to keep the item on the queue before it is deleted.
Default is 604,800 seconds (7 days). Maximum is 2,592,000 seconds (30 days).
* `instantiate`: Indicates, that method must make instances of `IronMQ::Message` class with request and response parameters and return them.

--

### Get Messages from a Queue

```ruby
# one message
message = queue.reserve_message # => #<IronMQ::Message:...>

# or N messages
messages = queue.reserve_messages(n: 7) # => [#<IronMQ::Message:...>, ...]
# alias:
#   Queue#reserve

# or message by ID
message = queue.get_message_by_id('5127bf043264140e863e2283')
# => #<IronMQ::Message:...>
# alias:
#   Queue#get_message
```

**Optional parameters:**

* `n`: The maximum number of messages to get. Default is 1. Maximum is 100.
* `timeout`: After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not go back onto the queue.
If not set, value from POST is used. Default is 60 seconds. Minimum is 30 seconds.
Maximum is 86,400 seconds (24 hours).
* `wait`: : Time in seconds to wait for a message to become available. This enables long polling. Default is 0 (does not wait), maximum is 30.
* `delete`: true/false. This will delete the message on get. Be careful though, only use this if you are ok with losing a message if something goes wrong after you get it. Default is false.

--

### Touch a Message on a Queue

Touching a reserved message extends its timeout by the duration specified when the message was created, which is 60 seconds by default.

```ruby
message = queue.reserve_message # => #<IronMQ::Message:...>
message.reservation_id # => "11111111"
message.touch! # => {"reservation_id" => "22222222", "msg" => "Touched"}
message.reservation_id # => "22222222"
```

--

### Release Message

```ruby
message = queue.reserve_message # => #<IronMQ::Message:...>
response = message.release! # => {"msg" => "Released"}
# or
response = message.release!(delay: 42) # => {"msg" => "Released"}
```

**Optional parameters:**

* `delay`: The item will not be available on the queue until this many seconds have passed.
Default is 0 seconds. Maximum is 604,800 seconds (7 days).

--

### Delete a Message from a Queue

```ruby
message = queue.reserve_message # => #<IronMQ::Message:...>
message.delete! # => {"msg" => "Deleted"}
```

--

### Peek Messages from a Queue

Peeking at a queue returns the next messages on the queue, but it does not reserve them.

```ruby
messages = queue.peek_messages # => [#<IronMQ::Message:...>]
# alias:
#   Queue#peek
#
# singular method:
#   Queue#peek_message

messages = queue.peek(n: 13) # => [#<IronMQ::Message:...>, ...]
```

**Optional parameters:**

* `n`: The maximum number of messages to peek. Default is 1. Maximum is 100.

--

### Clear a Queue

```ruby
queue.clear # => {"msg" => "Cleared"}
```

--

### Poll for Messages (Helper Method)

```ruby
queue.poll_messages(opts_for_reserve, poll_opts) do |msg|
  puts msg.body
end
```

Polling will automatically delete the message at the end of the block.

**Polling options:**

* `break_if_empty` - if API returns no messages, stop polling
* `sleep_duration` - sleep interval for the case, where queue is empty,
and `break_if_empty` is set to `false`. Default is 0.

--

## Push Queues

IronMQ push queues allow you to setup a queue that will push to an endpoint, rather than having to poll the endpoint. 
[Here's the announcement for an overview](http://blog.iron.io/2013/01/ironmq-push-queues-reliable-message.html). 

### Create a Push Queue

```ruby
options = {
  type: 'multicast',
  message_timeout: 120,
  message_expiration: 24 * 3600,
  push: {
    subscribers: [
      {
        name: 'subscriber_name',
        url: 'http://rest-test.iron.io/code/200?store=key1',
        headers: {
          'Content-Type' => 'application/json'
        }
      }
    ],
    retries: 3,
    retries_delay: 30,
    error_queue: 'error_queue_name'
  }
}

queue = ironmq.create_queue(queue_name, options) # => #<IronMQ::Queue:...>
```

**The following parameters are all related to Push Queues:**

* `push: subscribers`: An array of subscriber hashes containing a `name` and a `url` required fields,
and optional `headers` hash. `headers`'s keys are names and values are means of HTTP headers.
This set of subscribers will replace the existing subscribers.
To add or remove subscribers, see the add subscribers endpoint or the remove subscribers endpoint.
See below for example json.
* `push: retries`: How many times to retry on failure. Default is 3. Maximum is 100.
* `push: retries_delay`: Delay between each retry in seconds. Default is 60.
* `push: error_queue`: String. Queue name to post push errors to.

**Note:** queue type cannot be changed.

--

### Manage Subscribers

#### Add Subscribers to a Push Queue

```ruby
subscribers = [
    {
        name: 'first',
        url: 'http://first.endpoint.xx/process',
        headers: {
            Content-Type: 'application/json'
        }
    },
    {
        name: 'second',
        url: 'http://second.endpoint.xx/process',
    }
]
queue.add_subscribers(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#add_subscriber
```

To call `Queue.get_info!` after adding subscribers to keep information up-to-date:

```ruby
queue.add_subscribers!(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#add_subscriber!
```

#### Replace subscribers on a push queue

Sets list of subscribers to a queue. Older subscribers will be removed.

```ruby
subscribers = [
    {
        name: 'the_only',
        url: 'http://my.over9k.host.com/push'
    }
]
queue.replace_subscribers(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#replace_subscriber
```

To call `Queue.get_info!` after replacing subscribers to keep information up-to-date:

```ruby
queue.replace_subscribers!(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#replace_subscriber!
```

#### Remove subscribers by a name from a push queue

```ruby
subscribers = [
    {
        name: 'the_only'
    }
]
queue.remove_subscribers(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#remove_subscriber
```

To call `Queue.get_info!` after replacing subscribers to keep information up-to-date:

```ruby
queue.remove_subscribers!(subscribers) # => {"msg" => "Updated"}
# singular method:
#   Queue#remove_subscriber!
```

--

### Post and instantiate

Sometimes you may want to post message to the Push Queue and instantiate `Message`
instead getting it by ID returned in API response. To do this just set `:instantiate`
to `true`.

```ruby
message = queue.post('push me!', instantiate: true)
# => #<IronMQ::Message:...>

msgs = queue.post([{body: 'push'}, {body: 'me'}], instantiate: true)
# => [#<IronMQ::Message:...>, ...]
```

This creates fake `Message` objects. They contain only IDs.

--

### Get Message Push Status

After pushing a message:

```ruby
message = queue.get_message_by_id(msg_id)
message.push_statuses # => [{name: "sub-1", ...}, ...]

# with instantiated message, patch in-place
message.get_push_statuses! # => {"subscribers" => [...]}
message.push_statuses # => [{name: "sub-1", ...}, ...]
```

Returns an array of subscribers with status.

**Note:** getting a message by ID is only for usable for Push Queues.
This creates fake `IronMQ::Message` instance on which you call for subscribers' push statuses.

--

## Important Notes

* [Ruby 1.8 is no more supported](https://www.ruby-lang.org/en/news/2013/06/30/we-retire-1-8-7/).
* Queue type is static now. Once it is set, it cannot be changed.

## Further Links

* [IronMQ Overview](http://dev.iron.io/mq/3/)
* [IronMQ REST/HTTP API](http://dev.iron.io/mq/3/reference/api/)
* [Push Queues](http://dev.iron.io/mq/3/reference/push_queues/)
* [Other Client Libraries](http://dev.iron.io/mq/libraries/)
* [Live Chat, Support & Fun](http://get.iron.io/chat)

-------------
© 2011 - 2015 Iron.io Inc. All Rights Reserved.
