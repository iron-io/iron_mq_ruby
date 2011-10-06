require 'json'
require 'rest_client'


module IronMQ

  class Client

    attr_accessor :token, :project_id, :queue_name

    def initialize(options={})
      @token = options[:token] || options['token']
      @project_id = options[:project_id] || options['project_id']
      @queue_name = options[:queue_name] || options['queue_name']
      @scheme = options[:scheme] || options['scheme'] || "http"
      @host = options[:host] || options['host'] || "mq-aws-us-east-1.iron.io"
      @port = options[:port] || options['port'] || 80
      # todo: default https
      @base_url = "#{@scheme}://#{@host}:#{@port}/1"
    end

    def messages
      return Messages.new(self)
    end


    def post(path, params={})
      url = "#{@base_url}#{path}"
      puts 'url=' + url
      response = RestClient.post(url, {'oauth' => @token}.merge(params),
                                 :content_type => :json)
      puts 'response: ' + response.inspect
      res = JSON.parse(response)
      res
    end

    def get(path, params={})
      url = "#{@base_url}#{path}"
      puts 'url=' + url
      response = RestClient.get(url,
                                {:params => {'oauth'=>@token}.merge(params)})
      res = JSON.parse(response)
      res
    end

    def delete(path, params={})
      url = "#{@base_url}#{path}"
      puts 'url=' + url
      response = RestClient.delete(url,
                                         {:params => {'oauth'=>@token}.merge(params)})
      res = JSON.parse(response)
      puts 'response: ' + res.inspect
      res
    end

  end

  class Messages

    attr_accessor :client

    def initialize(client)
      @client = client
    end


    # options:
    #  :queue_name => can specify an alternative queue name
    def get(options={})
      path = "/projects/#{@client.project_id}/queues/#{options[:queue_name] || @client.queue_name}/messages"
      res = @client.get(path)
      res
    end

    # options:
    #  :queue_name => can specify an alternative queue name
    def post(payload, options={})
      path = "/projects/#{@client.project_id}/queues/#{options[:queue_name] || @client.queue_name}/messages"
      res = @client.post(path, :payload=>payload)
      res
    end

    def delete(message_id, options={})
      path = "/projects/#{@client.project_id}/queues/#{options[:queue_name] || @client.queue_name}/messages/#{message_id}"
      res = @client.delete(path)
      res
    end

  end

end

