# Migration Cheatsheet

This migration document covers transition from `iron_mq` gem version 5.x.x to version 6.x.x.
It includes removed, renamed, and new methods per class.

**NOTE:** bang methods (which end with `!`) update instance of appropriate class in-place.

## Client

#### Removed methods

```ruby
# Assume, that @client was created earlier
@client.list # alias of Client#queues_list
@client.all  # alias of Client#queues_list
@client.queues.* # all those methods were deprecated in v5
```

#### Renamed or Changed Methods

```ruby
@client.queues_get
# renamed to
@client.make_queue
# alias
@client.queue
# return Queue instance
```

`Client#queues_get` was able to construct `Queue` object from its name.
`Client#make_queue` accepts either name or queue's info hash.

```ruby
@client.queues_list
# renamed to
@client.get_queues
# alias
@client.queues
# return Array of Queues
```

`Client#get_queues` does not respect `:raw` option and always returns `Array` or `Queue`s.

#### New Methods

```ruby
@client.get_queue(queue_name) # => #<IronMQ::Queue:...>
@client.update_queue(queue_name, options) # => #<IronMQ::Queue:...>
@client.delete_queue(queue_name) # => Hash, that represents answer from the API
```

## Queue

#### Removed Methods

```ruby
# Assume, that @queue was created earlier
@queue.load
@queue.reload
@queue.id # queues do not have ID
@queue.get
@queue.get_messages # removed, because queue messages must be "reserved"
@queue.delete(message_id, options) # was deprecated in v5
@queue.messages.* # all methods were deprecated in v5
```

#### Renamed or Changed Methods

```ruby
@queue.update(options)
# renamed to
@queue.update!(options)
# alias
@queue.update_queue!(options)
# return Hash, that represents API response
```

```ruby
@queue.delete_queue
# renamed to
@queue.delete!
# alias
@queue.delete_queue!
# return Hash, that represents API response
```

`Queue`'s `*_subscribers` and `*_alerts` methods now have second attribute `reload`.
As shorthands, such methods have singular forms, like `add_alert`, and bang forms,
like `replace_subscriber!`. Bang methods additionally calls API to get fresh queue information.

`Queue#post_messages` accepts `Array` of `String`s bodies or `Hash`s messages representations.
As second argument, it accepts optional `Hash` of common messages options with additional `:instantiate` flag.
If the flag is not `nil` or `false`, response will be instantiated to `Array` of `Message`s with ID and body set.

```ruby
@queue.post_messages([{body: 'body #0'}, {body: 'body #1'}])
@queue.post_messages(['body #0', 'body #1'], instantiate: true)
```

`Queue#get_message` is alias of `Queue#get_message_by_id`.

`Queue#peek_messages` does not respect `:instantiate` flag and returns `Array` of `Message`s.

`Queue#poll_messages`, aliased as `Queue#poll`, respects `:n` option and calls block with each message.

`Queue#alerts` and `Queue#subscribers` return partial queue info as `Hash`, instead of `Alert` or `Subscriber` instances.

#### New Methods

```ruby
@queue.create!(options)
# returns Hash, that represents API response

@queue.get_info!
# alias
@queue.info!
# return Hash, that represents API response

@queue.reserve_messages(options) # This is new get, read more in API documentation
# alias
@queue.reserve(options)
# return Array of Messages

@queue.push_info # alias for :push field of queue info

@queue == other_queue # returns true if both queues have the same name and project ID

@queue.to_h # returns Hash representation of queue information
```

## Message

#### Removed Methods

```ruby
# Assume @msg is instance of Message class
@msg.timeout # field removed
@msg.expires_in # field removed
@msg.delay # field removed
```

#### Renamed or Changed Methods

`Message#subscribers` method returns partial message info, `Array` of subscribers `Hash`es.
To receive push statuses of message's subscribers, use `Message#get_push_statuses` or its bang antagonist.

```ruby
@msg.touch
# renamed to
@msg.touch!(options)
# alias
@msg.touch_message!(options)

@msg.release(options)
# renamed to
@msg.release!(options)
# alias
@msg.release_message!(options)

@msg.delete
# renamed to
@msg.delete!
# alias
@msg.delete_message!
```

#### New Methods

```ruby
# get message with @msg's ID and return Hash representation API response
@msg.get
# alias
@msg.get_message
# the same as above, but patch @msg itself
@msg.get!
# alias
@msg.get_message!

# get @msg's subscribers push statuses and return parsed API response as Hash
@msg.get_push_statuses
# its bang antagonist
@msg.get_push_statuses!

# get IDs (message's and reservation's)
@msg.ids # => {id: '123456', reservation_id: '111111'}

# is message reserved?
@msg.reserved? # true if reservation ID is nil or empty

@msg == other_message # returns true if IDs are equal

@msg.to_h # message's Hash representation
```

## Subscriber

Class was removed, because subscribers are property of queue info, particulary, push queues.

## Alert

Class was removed, because subscribers are property of queue info, particulary, pull queues.
