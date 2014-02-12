module IronMQ

  class Alert
    # `options` was kept for backward compatibility
    attr_accessor :options

    def initialize(queue, alert_hash, options = {})
      @queue = queue
      @raw = alert_hash
      @options = options
    end

    def id
      @raw['id']
    end

    # alert type
    def type
      @raw['type']
    end

    # target queue
    def queue
      @raw['queue']
    end

    def trigger
      @raw['trigger']
    end

    def direction
      @raw['direction']
    end

    def delay
      @raw['delay']
    end

    # `options` was kept for backward compatibility
    def delete(options = {})
      @message.call_api_and_parse_response(:delete, path)
    rescue Rest::HttpError => ex
      #if ex.code == 404
      #  IronCore::Logger.info('IronMQ', 'Delete got 404, safe to ignore.')
      #  # return ResponseBase as normal
      #  ResponseBase.new({'msg' => 'Deleted'}, 404)
      #else
        raise ex
      #end
    end

    alias_method :acknowledge, :delete

    private

    def path
      "/alerts/#{id}"
    end
  end

end
