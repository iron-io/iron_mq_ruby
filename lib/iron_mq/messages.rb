require 'cgi'

module IronMQ

  class Message < ResponseBase
    attr_reader :queue

    def initialize(queue, data)
      @queue = queue
      super(data, 200)
    end

    def touch
      call_api_and_parse_response(:post, "/touch")
    end

    def release(options = {})
      call_api_and_parse_response(:post, "/release", options)
    end

    # `options` was kept for backward compatibility
    def subscribers(options = {})
      response = call_api_and_parse_response(:get, "/subscribers", {}, false)

      response['subscribers'].each_with_object([]) do |subscriber, ret|
        ret << Subscriber.new(subscriber, self, options)
      end
    end

    def delete
      begin
        call_api_and_parse_response(:delete)
      rescue Rest::HttpError => ex
        if ex.code == 404
          Rest.logger.info("Delete got 404, safe to ignore.")
        else
          raise ex
        end
      end
    end

    def call_api_and_parse_response(meth, ext_path = "", options = {}, instantiate = true)
      @queue.call_api_and_parse_response(meth, "#{path(ext_path)}", options, instantiate)
    end

    private

    def path(ext_path)
      "/messages/#{id}#{ext_path}"
    end
  end

end
