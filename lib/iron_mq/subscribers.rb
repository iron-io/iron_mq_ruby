module IronMQ
  class Subscribers
    def self.path(options)
      path = "#{Messages.path(options)}/subscribers"
      if options[:subscriber_id]
        path << "/#{options[:subscriber_id]}"
      end
      path
    end
  end

  class Subscriber < ResponseBase
    attr_accessor :options

    def initialize(raw, message, options={})
      super(raw)
      @message = message
      @options = options
    end

    def delete(options={})
      client = @message.messages.client

      options[:subscriber_id] ||= @raw["id"]
      options[:msg_id] ||= @message.id
      options[:project_id] ||= client.project_id
      options[:queue_name] ||= client.queue_name
      path = Subscribers.path(options)
      raw = client.delete(path)
      res = client.parse_response(raw)
      ResponseBase.new(res)
    end
  end
end
