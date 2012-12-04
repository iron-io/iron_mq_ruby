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
    attr_reader :message

    def initialize(raw, message, options={})
      super(raw)
      @message = message
      @options = options
    end

    def delete(subscriber_id, options={})
      options[:subscriber_id] = subscriber_id
      res = @client.parse_response(@message.messages.client.delete(Subscribers.path(options)))
      return ResponseBase.new(res)
    end
  end
end

