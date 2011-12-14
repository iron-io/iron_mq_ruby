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
        params = nil
        if options[:timeout]
          params = {:timeout => options[:timeout]}
        end
        res, status = @client.get(path(options), params)
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
    def post(payload, options={})
      res, status = @client.post(path(options), :body=>payload)
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
