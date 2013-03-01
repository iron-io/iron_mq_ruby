module IronMQ

  class Subscriber < ResponseBase
    # `options` was kept for backward compatibility
    attr_accessor :options

    def initialize(data, message, options = {})
      super(data, 200)
      @message = message
      @options = options
    end

    # `options` was kept for backward compatibility
    def delete(options = {})
      @message.call_api_and_parse_response(:delete, path)
    end

    private

    def path
      "/subscribers/#{id}"
    end
  end

end
