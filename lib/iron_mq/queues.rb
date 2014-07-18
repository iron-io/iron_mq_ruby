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

      @raw['queue']
    end

    def reload
      @raw = call_api_and_parse_response(:get, '', {}, false, true)
      self
    end

    def id
      load['id']
    end

    def size
      load['size'].to_i
    end

    def total_messages
      load['total_messages'].to_i
    end

    def type
      load['type']
    end

    def push_queue?
      ['multicast', 'unicast'].include?(type)
    end

    def push_info
      load['push']
    end

    def update(options)
      call_api_and_parse_response(:put, "", options)
    end

    alias_method :update_queue, :update

    def clear
      call_api_and_parse_response(:delete, '/messages', {}, false, true)
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
    def delete(message_id, reservation_id = nil)
      # API does not accept any options
      options = {}
      options['id'] = message_id
      unless reservation_id.nil?
        options['reservation_id'] = reservation_id
      end
      Message.new(self, options).delete
    end

    # Accepts an array of message ids
    def delete_messages(ids)
      call_api_and_parse_response(:delete, '/messages', :ids => ids)
    end

    def delete_reserved_messages(messages)
      ids = messages.map {|message| {id: message.id, reservation_id: message.reservation_id }}
      call_api_and_parse_response(:delete, "/messages", :ids => ids)
    end

    def add_subscribers(subscribers)
      values = subscribers.map{|val| {url: val}}
      call_api_and_parse_response(:patch, "", queue: {push: {subscribers: values}})
    end

    # `options` for backward compatibility
    def add_subscriber(subscriber, options = {})
      add_subscribers([subscriber])
    end

    def remove_subscribers(subscribers)
      call_api_and_parse_response(:delete,
                                  '/subscribers',
                                  {
                                      :subscribers => subscribers,
                                      :headers => {'Content-Type' => @client.content_type}
                                  })
    end

    def remove_subscriber(subscriber)
      remove_subscribers([subscriber])
    end

    def clear_subscribers
      call_api_and_parse_response(:patch, "", queue: {push: {subscribers: [{}]}})
    end

    # `options` was kept for backward compatibility
    def subscribers(options = {})
      load
      return [] if info['push'].nil? || info['push']['subscribers'].nil?

      info['push']['subscribers'].map { |s| Subscriber.new(s, self, options) }
    end

    def add_alerts(alerts)
      call_api_and_parse_response(:patch, '', queue: {alerts: alerts})
    end

    def add_alert(alert)
      add_alerts([alert])
    end

    def remove_alerts(alerts)
      call_api_and_parse_response(:delete, '/alerts', :alerts => alerts)
    end

    def remove_alert(alert)
      remove_alerts([alert])
    end

    def replace_alerts(alerts)
      call_api_and_parse_response(:put, '/alerts', :alerts => alerts)
    end

    def clear_alerts
      replace_alerts([])
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

    def reserve_messages(options = {})
      resp = call_api_and_parse_response(:post, "/reservations", options, false)
      process_messages(resp["messages"], options)
    end

    # backwards compatibility
    alias_method :get, :reserve_messages
    alias_method :get_messages, :reserve_messages
    alias_method :reserve, :reserve_messages

    # Backward compatibility
    def messages
      self
    end

    def get_message(id)
      resp = call_api_and_parse_response(:get, "/messages/#{id}", {}, false)
      Message.new(self, resp['message'])
    end

    def peek_messages(options = {})
      resp = call_api_and_parse_response(:get, "/messages", options)

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
                   headers['Content-Type'] = "application/json"
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

