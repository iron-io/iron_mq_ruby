require 'cgi'

module IronMQ
  class Messages

    attr_reader :client, :queue

    def initialize(client, queue=nil)
      @client = client
      @queue = queue
    end


    def path(options={})
      options[:queue_name] ||= ((@queue ? @queue.name : nil) || @client.queue_name)
      options[:project_id] = @client.project_id
      Messages.path(options)
    end

    def self.path(options)
      path = "#{Queues.path(options)}/messages"
      if options[:msg_id]
        path << "/#{options[:msg_id]}"
      end
      path
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    #  :timeout => amount of time before message goes back on the queue
    def get(options={})
      if options.is_a?(String)
        # assume it's an id
        puts 'get_by_id'
        return Message.new(self, {'id'=>options}, options)
        #r = @client.get(path(:msg_id=>options))
        #p r
        #return r
      end
      res = @client.parse_response(@client.get(path(options), options))
      ret = []
      res["messages"].each do |m|
        ret << Message.new(self, m, options)
      end

      if options[:n] || options['n']
        ret
      else
        if ret.size > 0
          ret[0]
        else
          nil
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
        res
      else
        ResponseBase.new({"id" => res["ids"][0], "msg" => res["msg"]})
      end
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res = @client.parse_response(@client.delete(path2))
      ResponseBase.new(res)
    end

    def release(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}/release"
      res = @client.parse_response(@client.post(path2, options))
      ResponseBase.new(res)
    end

  end

  class Message < ResponseBase
    attr_reader :messages

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

    def subscribers(options={})
      res = @messages.client.get(@messages.path(options.merge(:msg_id => id)) + "/subscribers", options)
      res = @messages.client.parse_response(res)
      ret = []
      res['subscribers'].each do |m|
        ret << Subscriber.new(m, self, options)
      end
      ret
    end
  end
end
