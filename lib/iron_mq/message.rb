require 'iron_mq/entity'

module IronMQ
  class Message
    include Entity

    define_fields :id, :body, :reservation_id, :reserved_count,
                  :subscribers, :headers, :push_statuses

    def initialize(client, queue_name, msg_fields)
      @client = client
      if queue_name.nil? || queue_name.empty?
        fail ArgumentError, 'queue_name must be non-empty String'
      end
      @queue_name = queue_name
      self.entity = msg_fields

      fail ArgumentError, 'msg_fields must contain message ID' unless id
    end

    def get
      @client.call_api(:get, path)
    end

    alias get_message get

    def get!
      get.tap { |response| self.entity = response['message'] }
    end

    alias get_message! get!

    def touch!(options = {})
      return if reservation_id.nil? || reservation_id.empty?

      opts = keywordise_keys(options).merge!(reservation_id: reservation_id)
      @client.call_api(:post, path('/touch'), opts).tap do |response|
        self.entity = to_h.update(reservation_id: response['reservation_id'])
      end
    end

    alias touch_message! touch!

    def release!(options = {})
      return if reservation_id.nil? || reservation_id.empty?

      opts = keywordise_keys(options).merge!(reservation_id: reservation_id)
      @client.call_api(:post, path('/release'), opts).tap do |response|
        self.entity = to_h.update(reservation_id: nil)
      end
    end

    alias release_message! release!

    def delete!
      r_id = reservation_id
      response =
        if r_id.nil? || r_id.empty?
          @client.call_api(:delete, path, {},
                           'Content-Type' => 'application/json')
        else
          @client.call_api(:delete, path, reservation_id: r_id)
        end
      self.entity = to_h.update(reservation_id: nil)
      response
    end

    alias delete_message! delete!

    def get_push_statuses
      @client.call_api(:get, path('/subscribers'))
    end

    def get_push_statuses!
      get_push_statuses.tap do |response|
        self.entity = to_h.update(push_statuses: response['subscribers'])
      end
    end

    def ids
      entity.select do |f, v|
        [:id, :reservation_id].include?(f) && v && !v.empty?
      end
    end

    def ==(other)
      id == other.id
    end

    def hash; id.hash end

    private

    def path(ext_path = '')
      @base_path ||= "/#{@client.escape(@queue_name)}/messages/"

      "#{ @base_path }#{ id }#{ ext_path }"
    end
  end
end
