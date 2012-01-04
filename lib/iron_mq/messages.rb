module IronMQ
  class Messages

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def path(options={})
      path = "/projects/#{@client.project_id}/queues/#{options[:queue_name] || @client.queue_name}/messages"
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    #  :timeout => amount of time before message goes back on the queue
    def get(options={})
      begin
        res, status = @client.get(path(options), options)
        return Message.new(self, res)
      rescue IronMQ::Error => ex
        if ex.status == 404
          return nil
        end
        raise ex
      end


    end

    # options:
    #  :queue_name => can specify an alternative queue name
    #  :delay => time to wait before message will be available on the queue
    #  :timeout => The time in seconds to wait after message is taken off the queue, before it is put back on. Delete before :timeout to ensure it does not go back on the queue.
    #  :expires_in => After this time, message will be automatically removed from the queue.
    def post(payload, options={})
      options[:body] = payload
      res, status = @client.post(path(options), options)
      return Message.new(self, res)
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res, status = @client.delete(path2)
      res
    end

  end

  class Message

    def initialize(messages, res)
      @messages = messages
      @data = res
    end

    def raw
      @data
    end

    def [](key)
      raw[key]
    end

    def id
      raw["id"]
    end

    def body
      raw["body"]
    end

    def delete
      @messages.delete(self.id)
    end
  end

end
