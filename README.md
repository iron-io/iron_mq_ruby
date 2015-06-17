
## Set up
```ruby
require “iron_client”

IronClient::Swagger.configure do |c|
	c.auth_token = AUTH_TOKEN # This is where you oauth token goes.
	c.host = HOST # defaults to mq-aws-us-east-1-1.iron.io
end
```

From there, you can make function calls to the api like so

```ruby
messages = { messages:
              [{
                body: "Message 1"
              }, {
                body: "Message 2"
              }]}

# Post the messages
response = IronClient::IronMQApi.post_messages(PROJECT_ID, QUEUE_NAME, messages)

# Get the ids of the messages just posted
id_list = response.ids
```
