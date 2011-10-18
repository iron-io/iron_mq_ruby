require 'json'
require 'patron'
require 'logger'

module IronMQ

  class Client

    attr_accessor :token, :project_id, :queue_name, :base_url, :logger

    def initialize(options={})
      @logger = Logger.new(STDOUT)
      @logger.level=Logger::INFO

      @token = options[:token] || options['token']
      @project_id = options[:project_id] || options['project_id']
      @queue_name = options[:queue_name] || options['queue_name'] || "default"
      @scheme = options[:scheme] || options['scheme'] || "https"
      @host = options[:host] || options['host'] || "mq-aws-us-east-1.iron.io"
      @port = options[:port] || options['port'] || 443
      # todo: default https
      @base_url = "#{@scheme}://#{@host}:#{@port}/1"

      sess = Patron::Session.new
      sess.timeout = 10
      sess.base_url = @base_url
      sess.headers['User-Agent'] = 'IronMQ Ruby Client'
      #sess.enable_debug "/tmp/patron.debug"
      @http_sess = sess

    end

    def messages
      return Messages.new(self)
    end


    def post(path, params={})
      url = "#{@base_url}#{path}"
      @logger.debug 'url=' + url
      response = @http_sess.post(path + "?oauth=#{@token}", {'oauth' => @token}.merge(params).to_json, {"Content-Type" => 'application/json'})
      check_response(response)
      @logger.debug 'response: ' + response.inspect
      body = response.body
      res = JSON.parse(body)
      return res, response.status
    end

    def get(path, params={})
      url = "#{@base_url}#{path}"
      @logger.debug 'url=' + url
      response = @http_sess.request(:get, path,
                                    {},
                                    :query=>{'oauth'=>@token}.merge(params))
      res = check_response(response)

      return res, response.status
    end

    def delete(path, params={})
      url = "#{@base_url}#{path}"
      @logger.debug 'url=' + url
      response = @http_sess.request(:delete, path,
                                    {},
                                    :query=>{'oauth'=>@token}.merge(params))
      check_response(response)
      body = response.body
      res = JSON.parse(body)
      @logger.debug 'response: ' + res.inspect
      return res, response.status
    end

    def check_response(response)
      status = response.status
      body = response.body
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

  class Messages

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def path(options={})
      path = "/projects/#{@client.project_id}/queues/#{options[:queue_name] || @client.queue_name}/messages"
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    def get(options={})
      begin
        res, status = @client.get(path(options))
        return Message.new(self, res)
      rescue IronMQ::Error => ex
        if ex.status == 404
          return nil
        end
      end


    end

    # options:
    #  :queue_name => can specify an alternative queue name
    def post(payload, options={})
      res, status = @client.post(path(options), :body=>payload)
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res, status = @client.delete(path2)
      res
    end

  end

  class Message

    def initialize(messages, res)
      @messages = messages
      @data = res
    end

    def raw
      @data
    end

    def [](key)
      raw[key]
    end

    def id
      raw["id"]
    end

    def body
      raw["body"]
    end

    def delete
      @messages.delete(self.id)
    end
  end

end

