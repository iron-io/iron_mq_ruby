require 'iron_mq/entity'

module IronMQ
  class Queue
    include Entity

    define_fields :name, :project_id, :type, :size, :total_messages,
                  :message_timeout, :message_expiration, :alerts, :push

    def initialize(client, name_or_fields)
      @client = client

      self.entity =
        case name_or_fields
        when String # queue name
          {name: name_or_fields, project_id: @client.project_id}
        when Hash # queue info
          if name_or_fields.keys.none? { |k| k.to_sym == :project_id }
            name_or_fields.merge(project_id: @client.project_id)
          else
            name_or_fields
          end
        else
          fail ArgumentError, '2nd argument must be queue name or hash'
        end

      fail ArgumentError, 'queue name is not set' if name.nil? || name.empty?
      fail ArgumentError, 'wrong project ID' if project_id != @client.project_id
    end

    def create!(options = {})
      opts = to_h.merge(options)
      with_info_reload { @client.call_api(:put, path, queue: opts) }
    end

    def get_info!
      with_info_reload { @client.call_api(:get, path) }
    end

    alias info! get_info!

    def get_info(reload = false)
      reload ? get_info! : to_h
    end

    alias info get_info

    def push_queue?
      ['multicast', 'unicast'].include?(type)
    end

    def push_info; push end

    def subscribers
      push_queue? ? push_info[:subscribers] : nil
    end

    def update!(options = {})
      with_info_reload { @client.call_api(:patch, path, queue: options) }
    end

    alias update_queue! update!

    def delete!
      response = @client.call_api(:delete, path)
      self.entity = {name: name, project_id: @client.project_id}
      response
    end

    alias delete_queue! delete!

    def add_subscribers(subscribers, reload = false)
      with_info_reload(reload) do
        @client.call_api(:post, path('/subscribers'), subscribers: subscribers)
      end
    end

    def add_subscriber(subscriber, reload = false)
      add_subscribers([subscriber], reload)
    end

    def add_subscribers!(subscribers)
      add_subscribers(subscribers, true)
    end

    def add_subscriber!(subscriber)
      add_subscribers([subscriber], true)
    end

    def remove_subscribers(subscribers, reload = false)
      with_info_reload(reload) do
        @client.call_api(:delete, path('/subscribers'),
                         subscribers: subscribers)
      end
    end
 
    def remove_subscriber(subscriber, reload = false)
      remove_subscribers([subscriber], reload)
    end

    def remove_subscribers!(subscribers)
      remove_subscribers(subscribers, true)
    end
    
    def remove_subscriber!(subscriber)
      remove_subscribers([subscriber], true)
    end

    def replace_subscribers(subscribers, reload = false)
      with_info_reload(reload) do
        @client.call_api(:put, path('/subscribers'), subscribers: subscribers)
      end
    end

    def replace_subscriber(subscriber, reload = false)
      replace_subscribers([subscriber], reload)
    end

    def replace_subscribers!(subscribers)
      replace_subscribers(subscribers, true)
    end

    def replace_subscriber!(subscriber)
      replace_subscribers([subscriber], true)
    end

    def add_alerts(alerts, reload = false)
      with_info_reload(reload) do
        @client.call_api(:patch, path('/alerts'), queue: {alerts: alerts})
      end
    end

    def add_alert(alert, reload = false)
      add_alerts([alert], reload)
    end

    def add_alerts!(alerts)
      add_alerts(alerts, true)
    end

    def add_alert!(alert)
      add_alerts([alert], true)
    end

    def remove_alerts(alerts, reload = false)
      with_info_reload(reload) do
        @client.call_api(:delete, path('/alerts'), alerts: alerts)
      end
    end

    def remove_alert(alert, reload = false)
      remove_alerts([alert], reload)
    end

    def remove_alerts!(alerts)
      remove_alerts(alerts, true)
    end

    def remove_alert!(alert)
      remove_alerts([alert], true)
    end

    def replace_alerts(alerts, reload = false)
      with_info_reload(reload) do
        @client.call_api(:put, path('/alerts'), alerts: alerts)
      end
    end

    def replace_alerts!(alerts)
      replace_alerts(alerts, true)
    end

    def clear_alerts(reload = false)
      with_info_reload(reload) { replace_alerts([]) }
    end

    def clear_alerts!
      clear_alerts(true)
    end

    def post_messages(messages, options = {})
      opts = keywordise_keys options
      instantiate = opts.delete(:instantiate)

      msgs = messages.each_with_object([]) do |msg, res|
        m = case msg
            when Hash then keywordise_keys msg
            when String then {body: msg}
            else fail ArgumentError, 'messages can be Strings or Hashes'
            end
        res << opts.merge(m)
      end

      response = @client.call_api(:post, path('/messages'), messages: msgs)
      if instantiate
        msgs.zip(response['ids']).map do |msg, id|
          Message.new(@client, self.name, msg.merge(id: id))
        end
      else
        response
      end
    end

    alias post post_messages

    def post_message(message, options = {})
      res = post_messages([message], options)
      res.is_a?(Array) ? res.first : res
    end

    def reserve_messages(options = {})
      response = @client.call_api(:post, path('/reservations'), options)
      make_messages response['messages']
    end

    alias reserve reserve_messages

    def reserve_message(options = {})
      reserve_messages(keywordise_keys(options).merge!(n: 1)).first
    end

    def get_message_by_id(id)
      response = @client.call_api(:get, path("/messages/#{id}"))
      Message.new(@client, self.name, response['message'])
    end

    alias get_message get_message_by_id

    def peek_messages(options = {})
      response = @client.call_api(:get, path('/messages'), options)
      make_messages response['messages']
    end

    alias peek peek_messages

    def peek_message
      peek_messages(n: 1).first
    end

    def delete_messages(messages)
      ids = messages.map do |message|
        case message
        when Message then message.ids
        when Hash then message
        else {id: message}
        end
      end

      @client.call_api(:delete, path('/messages'), ids: ids)
    end

    def delete_message(message)
      delete_messages([message])
    end

    def delete_all_messages
      @client.call_api(:delete, path('/messages'), {},
                       'Content-Type' => 'application/json')
    end

    alias clear delete_all_messages
    alias clear_queue delete_all_messages

    def poll_messages(api_opts = {}, poll_opts = {}, &block)
      return unless block_given?

      opts = keywordise_keys(poll_opts)
      slp, break_empty = opts.values_at(:sleep_duration, :break_if_empty)
      slp = slp.to_f # supports a fraction of a second
      loop do
        msgs = reserve_messages(api_opts)
        if msgs.empty?
          break_empty ? break : sleep(slp)
        else
          msgs.each do |msg|
            block.call(msg)

            msg.delete!
          end
        end
      end
    end

    alias poll poll_messages

    def ==(other)
      name == other.name && project_id == other.project_id
    end

    def hash
      name.hash ^ project_id.hash
    end

    private

    def path(ext_path = '')
      @escaped_name ||= @client.escape(name)

      "/#{@escaped_name}#{ext_path}"
    end

    def make_messages(hashes)
      hashes.map { |m_hash| Message.new(@client, self.name, m_hash) }
    end

    def with_info_reload(force_reload = false, &block)
      return info(force_reload) unless block_given?

      response = block.call
      if response['queue']
        self.entity = response['queue']
      elsif force_reload
        get_info!
      end

      response
    end
  end
end
