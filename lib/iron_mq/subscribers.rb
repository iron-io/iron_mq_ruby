module IronMQ

  class Subscriber < ResponseBase
    # `options` was kept for backward compatibility
    attr_accessor :options

    def initialize(data, message, options = {})
      super(data, 200)
      @message = message
      @options = options
    end

    def url
      @raw['url']
    end

    def headers
      @raw['headers']
    end

    # `options` was kept for backward compatibility
    def delete(options = {})
      @message.call_api_and_parse_response(:delete, path)
    rescue Rest::HttpError => ex
      #if ex.code == 404
      #  Rest.logger.info("Delete got 404, safe to ignore.")
      #  # return ResponseBase as normal
      #  ResponseBase.new({"msg" => "Deleted"}, 404)
      #else
        raise ex
      #end
    end

    alias_method :acknowledge, :delete

    private

    def path
      "/subscribers/#{id}"
    end
  end

end
