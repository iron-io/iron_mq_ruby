require 'cgi'

module IronMQ

  class Queue < ResponseBase
    attr_reader :name, :raw

    def initialize(client, queue_name)
      @client = client
      @name = queue_name
    end

    def info
      load
    end

    # this is only run once if it hasn't been called before unless force is true, then it will force reload.
    def load
      reload if @raw.nil?

      @raw
    end

    def reload
      @raw = call_api_and_parse_response(:get, "", {}, false, true)
      self
    end

    def id
      load
      @raw['id']
    end

    def size
      load
      @raw['size'].to_i
    end

    def total_messages
      load
      @raw['total_messages'].to_i
    end

    def push_type
      load
      @raw['push_type']
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
      call_api_and_parse_response(:post, "/clear", {}, false, true)
    end

    alias_method :clear_queue, :clear

    # Backward compatibility, better name is `delete`
    def delete_queue
      r = call_api_and_parse_response(:delete)
      @raw = nil
      return r
    rescue Rest::HttpError => ex
      #if ex.code == 404
      #  Rest.logger.info("Delete got 404, safe to ignore.")
      #  # return ResponseBase as normal
      #  ResponseBase.new({"msg" => "Deleted"}, 404)
      #else
        raise ex
      #end
    end

    # Backward compatibility
    def delete(message_id, options = {})
      # API does not accept any options
      Message.new(self, {"id" => message_id}).delete
    end

    # Accepts an array of message ids
    def delete_messages(ids)
      call_api_and_parse_response(:delete, "/messages", :ids => ids)
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

    # `options` was kept for backward compatibility
    def subscribers(options = {})
      load
      if @raw['subscribers']
        return @raw['subscribers'].map { |s| Subscriber.new(s, self, options) }
      end
      []
    end

    def add_alert(alert)
      add_alerts([alert])
    end

    def add_alerts(alerts)
      call_api_and_parse_response(:post, '/alerts', :alerts => alerts)
    end

    def remove_alerts(alerts)
      call_api_and_parse_response(:delete, '/alerts', :alerts => alerts)
    end

    def remove_alert(alert)
      remove_alerts([alert])
    end

    def alerts
      load
      return nil unless @raw['alerts']
      to_alerts(@raw['alerts'])
    end

    def post_messages(payload, options = {})
      batch = false

      instantiate = [options.delete(:instantiate),
                     options.delete('instantiate')].compact.first

      msgs = if payload.is_a?(Array)
               batch = true
               # FIXME: This maybe better to process Array of Objects the same way as for single message.
               #
               #          payload.map { |msg| options.merge(:body => msg) }
               #
               #        For now user must pass objects like `[{:body => msg1}, {:body => msg2}]`
               payload.map { |msg| msg.merge(options) }
             else
               [options.merge(:body => payload)]
             end

      # Do not instantiate response
      res = call_api_and_parse_response(:post, "/messages", {:messages => msgs}, false)

      if instantiate
        n = batch ? 2 : 1
        msg_ids = res["ids"].map { |id| {"id" => id} }

        process_messages(msg_ids, {:n => n})
      else
        if batch
          # FIXME: Return Array of ResponseBase instead, it seems more clear than raw response
          #
          #          res["ids"].map { |id| ResponseBase.new({"id" => id, "msg" => res["msg"]}) }
          #
          ResponseBase.new(res) # Backward capable
        else
          ResponseBase.new({"id" => res["ids"][0], "msg" => res["msg"]})
        end
      end
    end

    alias_method :post, :post_messages

    def get_messages(options = {})
      if options.is_a?(String)
        # assume it's an id
        return Message.new(self, {"id" => options})
      end

      resp = call_api_and_parse_response(:get, "/messages", options, false)

      process_messages(resp["messages"], options)
    end

    alias_method :get, :get_messages

    # Backward compatibility
    def messages
      self
    end

    def get_message(id)
      resp = call_api_and_parse_response(:get, "/messages/#{id}", {}, false)
      Message.new(self, resp)
    end

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

    def call_api_and_parse_response(meth, ext_path = "", options = {}, instantiate = true, ignore404 = false)
      r = nil
      response = if meth.to_s == "delete"
                   headers = options.delete(:headers) || options.delete("headers") || {}

                   @client.parse_response(@client.send(meth, "#{path(ext_path)}", options, headers))
                 else
                   @client.parse_response(@client.send(meth, "#{path(ext_path)}", options))
                 end
      r = instantiate ? ResponseBase.new(response) : response
      r
    end

    private

    def to_alerts(alert_array)
      alert_array.each_with_object([]) { |a, res| res << Alert.new(self, a) }
    end

    def path(ext_path)
      "/#{CGI::escape(@name).gsub('+', '%20')}#{ext_path}"
    end

    def process_messages(messages, options)
      multiple = wait_for_multiple?(options)

      if messages.is_a?(Array) && messages.size > 0
        msgs = messages.map { |m| Message.new(self, m) }

        multiple ? msgs : msgs[0]
      else
        multiple ? [] : nil
      end
    end

    def wait_for_multiple?(options)
      options.is_a?(Hash) && ((options[:n] || options['n']).to_i > 1)
    end
  end

end

