require 'json'
require 'rest_client'
require 'patron'


module IronMQ

  class Client

    attr_accessor :token, :project_id, :queue_name, :base_url

    def initialize(options={})
      @token = options[:token] || options['token']
      @project_id = options[:project_id] || options['project_id']
      @queue_name = options[:queue_name] || options['queue_name']
      @scheme = options[:scheme] || options['scheme'] || "http"
      @host = options[:host] || options['host'] || "mq-aws-us-east-1.iron.io"
      @port = options[:port] || options['port'] || 80
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
      puts 'url=' + url
      response = @http_sess.post(path, {'oauth' => @token}.merge(params))
      #{:content_type => 'application/json'})
      puts 'response: ' + response.inspect
      body = response.body
      res = JSON.parse(body)
      res
    end

    def get(path, params={})
      url = "#{@base_url}#{path}"
      puts 'url=' + url
      response = @http_sess.request(:get, path,
                                    {},
                                    :query=>{'oauth'=>@token}.merge(params))
      body = response.body
      res = JSON.parse(body)
      res
    end

    def delete(path, params={})
      url = "#{@base_url}#{path}"
      puts 'url=' + url
      response = @http_sess.request(:delete, path,
                                    {},
                                    :query=>{'oauth'=>@token}.merge(params))
      body = response.body
      res = JSON.parse(body)
      puts 'response: ' + res.inspect
      res
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
      res = @client.get(path(options))
      res
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    def post(payload, options={})
      res = @client.post(path(options), :payload=>payload)
      res
    end

    def delete(message_id, options={})
      path2 = "#{self.path(options)}/#{message_id}"
      res = @client.delete(path2)
      res
    end

  end

end

