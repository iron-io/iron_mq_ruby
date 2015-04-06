require 'yaml'
require 'iron_core'

module IronMQ
  class Client < IronCore::Client
    AWS_US_EAST_HOST = 'mq-aws-us-east-1-1.iron.io'

    attr_accessor :logger

    def initialize(options={})
      default_options = {
          scheme: 'https',
          host: IronMQ::Client::AWS_US_EAST_HOST,
          port: 443,
          api_version: 3,
          user_agent: 'iron_mq_ruby-' + IronMQ::VERSION +
                      ' (iron_core_ruby-' + IronCore.version + ')'
      }

      super('iron', 'mq', options, default_options,
            [:project_id, :token, :api_version])

      fail ArgumentError, 'supported API version is 3+' if api_version < 3

      if @keystone.nil?
        if @token.nil?
          IronCore::Logger.error 'IronMQ', 'Token is not set', IronCore::Error
        end

        check_id(@project_id, 'project_id')
      end

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    def headers
      auth = "OAuth #{@token_provider ? @token_provider.token : @token}"
      super.merge('Authorization' => auth)
    end

    def base_url
      @base_url ||= "#{super}#{@api_version}/projects/#{@project_id}/queues"
    end

    def call_api(method, *args)
      parse_response send(method, *args)
    end

    def make_queue(queue_name_or_info)
      Queue.new(self, queue_name_or_info)
    end

    alias queue make_queue

    def create_queue(queue_name, options = {})
      response = call_api(:put, "/#{escape(queue_name)}", queue: options)
      make_queue response['queue']
    end

    def get_queues(options = {})
      response = call_api(:get, '', options)
      response['queues'].map { |qi| make_queue(qi) }
    end

    alias queues get_queues

    def get_queue(queue_name)
      response = call_api(:get, "/#{escape(queue_name)}")
      make_queue response['queue']
    end

    def update_queue(queue_name, options)
      response = call_api(:patch, "/#{escape(queue_name)}", queue: options)
      make_queue response['queue']
    end

    def delete_queue(queue_name)
      call_api(:delete, "/#{escape(queue_name)}")
    end

    def escape(str)
      CGI::escape(str).gsub('+', '%20')
    end
  end
end
