require 'cgi'
require 'iron_mq/subscribers'

module IronMQ

  class Queue < ResponseBase
    attr_reader :name

    def initialize(client, queue_name)
      @client = client
      @name = queue_name
      super({"name" => queue_name})
    end

    def info
      info  = raw
      begin
        # Do not instantiate response
        info = call_api_and_parse_response(:get, '', {}, false)
      rescue Rest::HttpError
      end

      ResponseBase.new(info)
    end

    def size
      info.size.to_i
    end

    def total_messages
      info.total_messages.to_i
    end

    def new?
      id.nil?
    end

    def push_queue?
      # FIXME: `push_type` parameter in not guaranted it's push queue.
      #        When the parameter absent it is not guaranted that queue is not push queue.
      ptype = push_type
      not (ptype.nil? || ptype.empty?)
    end

    def update(options)
      call_api_and_parse_response(:post, "", options)
    end

    alias_method :update_queue, :update

    def clear
      call_api_and_parse_response(:post, "/clear")
    end

    alias_method :clear_queue, :clear

    # Backward compatibility, better name is `delete`
    def delete_queue
      call_api_and_parse_response(:delete)
    end

    # Backward compatibility
    def delete(message_id, options = {})
      # API does not accept any options
      Message.new(self, {"id" => message_id}).delete
    end

    def add_subscribers(subscribers)
      call_api_and_parse_response(:post, "/subscribers", :subscribers => subscribers)
    end

    # `options` for backward compatibility
    def add_subscriber(subscriber, options = {})
      add_subscribers([subscriber])
    end

    def remove_subscribers(subscribers)
      call_api_and_parse_response(:delete,
                                  "/subscribers",
                                  {
                                    :subscribers => subscribers,
                                    :headers => {"Content-Type" => @client.content_type}
                                  })
    end

    def remove_subscriber(subscriber)
      remove_subscribers([subscriber])
    end

    def post_messages(payload, options = {})
      batch = false

      msgs = if payload.is_a?(Array)
               batch = true
               # FIXME: This maybe better to process Array of Objects the same way as for single message.
               #
               #          payload.each_with_object([]) do |msg, res|
               #            res << options.merge(:body => msg)
               #          end
               #
               #        For now user must pass objects like `[{:body => msg1}, {:body => msg2}]`
               payload.each_with_object([]) do |msg, res|
                 res << msg.merge(options)
               end
             else
               [ options.merge(:body => payload) ]
             end

      # Do not instantiate response
      res = call_api_and_parse_response(:post, "/messages", {:messages => msgs}, false)

      if batch
        # FIXME: Return Array of ResponsBase instead, it seems more clear than raw response
        #
        #          res["ids"].each_with_object([]) do |id, responses|
        #            responses << ResponseBase.new({"id" => id, "msg" => res["msg"]})
        #          end
        ResponseBase.new(res) # Backward capable
      else
        ResponseBase.new({"id" => res["ids"][0], "msg" => res["msg"]})
      end
    end

    alias_method :post, :post_messages

    def get_messages(options = {})
      if options.is_a?(String)
        # assume it's an id
        return Message.new(self, {"id" => options})
      end

      resp = call_api_and_parse_response(:get, "/messages", options)

      process_messages(resp["messages"], options)
    end

    alias_method :get, :get_messages

    # Backward compatibility
    def messages ; self; end

    def peek_messages(options = {})
      resp = call_api_and_parse_response(:get, "/messages/peek", options)

      process_messages(resp["messages"], options)
    end

    alias_method :peek, :peek_messages

    def poll_messages(options = {}, &block)
      sleep_duration = options[:sleep_duration] || 1
      
      while true
        msg = get_messages(options.merge(:n => 1))
        if msg.nil?
          options[:break_if_nil] ? break : sleep(sleep_duration)
        else
          yield msg
          # Delete message after processing
          msg.delete
        end
      end
    end

    alias_method :poll, :poll_messages

    def call_api_and_parse_response(meth, ext_path = "", options = {}, instantiate = true)
      response = if meth.to_s == "delete"
                   headers = options.delete(:headers) || options.delete("headers") || {}

                   @client.parse_response(@client.send(meth, "#{path(ext_path)}", options, headers))
                 else
                   @client.parse_response(@client.send(meth, "#{path(ext_path)}", options))
                 end
      instantiate ? ResponseBase.new(response) : response
    end

    def method_missing(meth, *args)
      # This is for reload queue info data when calling:
      #   queue.id
      #   queue.size
      # etc.
      if args.length == 0
        res = info.send(meth)
        res ? res : super
      else
        super
      end
    end

    private

    def path(ext_path)
      "/#{CGI::escape(@name).gsub('+', '%20')}#{ext_path}"
    end

    def process_messages(messages, options)
      multiple = wait_for_multiple?(options)

      if messages.is_a?(Array) && messages.size > 0
        if multiple
          messages.each_with_object([]) do |m, msgs|
            msgs << Message.new(self, m)
          end
        else
          Message.new(self, messages[0])
        end
      else
        multiple ? [] : nil
      end
    end

    def wait_for_multiple?(options)
      options.is_a?(Hash) && ((options[:n] || options['n']).to_i > 1)
    end
  end

end

