require 'cgi'

module IronMQ
  class Messages

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def path(options={})
      path = "projects/#{@client.project_id}/queues/#{CGI::escape(options[:queue_name] || options['queue_name'] || @client.queue_name)}/messages"
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    #  :timeout => amount of time before message goes back on the queue
    def get(options={})
      res = @client.parse_response(@client.get(path(options), options))
      ret = []
      res["messages"].each do |m|
        ret << Message.new(self, m, options)
      end
      if options[:n] || options['n']
        return ret
      else
        if ret.size > 0
          return ret[0]
        else
          return nil
        end
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
      res = @client.parse_response(@client.post(path(options), to_send))
      if batch
        return res
      else
        return ResponseBase.new({"id"=>res["ids"][0], "msg"=>res["msg"]})
      end
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res = @client.parse_response(@client.delete(path2))
      return ResponseBase.new(res)
    end

    def release(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}/release"
      res = @client.parse_response(@client.post(path2, options))
      return ResponseBase.new(res)
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

    def initialize(messages, res, options={})
      super(res)
      @messages = messages
      @options = options
    end


    def body
      raw["body"]
    end

    def delete
      @messages.delete(self.id, @options)
    end

    def release(options={})
      options2 = options || {}
      options2 = options.merge(@options) if @options
      @messages.release(self.id, options2)
    end
  end

end
