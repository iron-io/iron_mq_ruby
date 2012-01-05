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
        ret = []
        res["messages"].each do |m|
          ret << Message.new(self, m)
        end
        if options[:n]
          return ret
        else
          if ret.size > 0
            return ret[0]
          else
            return nil
          end
        end
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
      batch = false
      if payload.is_a?(Array)
        batch = true
        msgs = payload
      else
        options[:body] = payload
        msgs = []
        msgs << options
      end
      to_send = {}
      to_send[:messages] = msgs
      res, status = @client.post(path(options), to_send)
      #return Message.new(self, res)
      if batch
        return res
      else
        return ResponseBase.new({"id"=>res["ids"][0], "msg"=>res["msg"]})
      end
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res, status = @client.delete(path2)
      res
    end

  end

  class ResponseBase
    def initialize(res)
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

    def msg
      raw["msg"]
    end

  end

  class Message < ResponseBase

    def initialize(messages, res)
      super(res)
      @messages = messages
    end


    def body
      raw["body"]
    end

    def delete
      @messages.delete(self.id)
    end
  end

end
