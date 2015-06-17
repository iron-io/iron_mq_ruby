# Getting Started

1. Install the gem
```
gem install iron_client
```

2. Set up your credentials and host
```
IronClient::Swagger.configure do |c|
	c.auth_token = AUTH_TOKEN # This is where you oauth token goes.
	c.host = HOST # defaults to mq-aws-us-east-1-1.iron.io
end
```

From there, you can make function calls to the api like so

```ruby

# Let's post a few messages onto a queue
messages = { messages:
              [{
                body: "Message 1"
              }, {
                body: "Message 2"
              }]}

# Post the messages
response = IronClient::IronMQApi.post_messages(PROJECT_ID, QUEUE_NAME, messages)

# Here are the ids of the messages we just posted
id_list = response.ids


# Let's grab some messages from our queue and reserve them

res = IronClient::IronMQApi.reserve_messages(PROJECT_ID, QUEUE_NAME, {n: 5})
messages = res.messages

messages.each do |m|
  puts "#{m.id}: #{m.body}"
end

# Lets delete these messages from the queue
ids = reserved_messages.messages.collect{|m| {id: m.id, reservation_id: m.reservation_id} }
IronClient::IronMQApi.delete_messages PROJECT_ID, QUEUE_NAME, {ids: ids}
```
