require 'json'
require 'typhoeus'
require 'logger'

module IronMQ

  class Client

    attr_accessor :token, :project_id, :queue_name, :logger

    def initialize(options={})
      @logger = Logger.new(STDOUT)
      @logger.level=Logger::INFO

      @token = options[:token] || options['token']
      @project_id = options[:project_id] || options['project_id']
      @queue_name = options[:queue_name] || options['queue_name'] || "default"
      @scheme = options[:scheme] || options['scheme'] || "https"
      @host = options[:host] || options['host'] || "mq-aws-us-east-1.iron.io"
      @port = options[:port] || options['port'] || 443

      @base_url = "#{@scheme}://#{@host}:#{@port}/1"

    end

    def messages
      return Messages.new(self)
    end

    def queues
      return Queues.new(self)
    end

    def base_url
      #"#{scheme}://#{host}:#{port}/1"
      @base_url
    end

    def full_url(path)
      url = "#{base_url}#{path}"
      url
    end

    def common_req_hash
      {
          :headers=>{"Content-Type" => 'application/json',
                     "Authorization"=>"OAuth #{@token}",
                     "User-Agent"=>"IronMQ Ruby Client"}
      }
    end

    def post(path, params={})
      url = full_url(path)
      @logger.debug 'url=' + url
      #response = @http_sess.post(path + "?oauth=#{@token}", {'oauth' => @token}.merge(params).to_json, {"Content-Type" => 'application/json'})
      req_hash = common_req_hash
      req_hash[:body] = params.to_json
      response = Typhoeus::Request.post(url, req_hash)
      @logger.debug 'typhoeus response=' + response.inspect
      res = check_response(response)
      #@logger.debug 'response: ' + res.inspect
      #body = response.body
      #res = JSON.parse(body)
      return res, response.code
    end

    def get(path, params={})
      url = full_url(path)
      @logger.debug 'url=' + url
      req_hash = common_req_hash
      req_hash[:params] = params
      response = Typhoeus::Request.get(url, req_hash)
      res = check_response(response)
      return res, response.code
    end

    def delete(path, params={})
      url = "#{base_url}#{path}"
      @logger.debug 'url=' + url
      req_hash = common_req_hash
      req_hash[:params] = params
      response = Typhoeus::Request.delete(url, req_hash)
      res = check_response(response)
      #body = response.body
      #res = JSON.parse(body)
      #@logger.debug 'response: ' + res.inspect
      return res, response.code
    end

    def check_response(response)
      # response.code    # http status code
      #response.time    # time in seconds the request took
      #response.headers # the http headers
      #response.headers_hash # http headers put into a hash
      #response.body    # the response body
      status = response.code
      body = response.body
      # todo: check content-type == application/json before parsing
      @logger.debug "response code=" + status.to_s
      @logger.debug "response body=" + body.inspect
      res = JSON.parse(body)
      if status < 400

      else
        raise IronMQ::Error.new(res["msg"], :status=>status)
      end
      res
    end

  end

  class Error < StandardError
    def initialize(msg, options={})
      super(msg)
      @options = options
    end

    def status
      @options[:status]
    end
  end


end

