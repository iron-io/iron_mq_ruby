require 'yaml'

require 'iron_core'
require 'iron_mq/queues'

module IronMQ

  class Client < IronCore::Client
    AWS_US_EAST_HOST = 'mq-aws-us-east-1.iron.io'

    attr_accessor :queue_name, :logger

    def initialize(options={})
      default_options = {
          :scheme => 'https',
          :host => IronMQ::Client::AWS_US_EAST_HOST,
          :port => 443,
          :api_version => 1,
          :user_agent => 'iron_mq_ruby-' + IronMQ::VERSION + ' (iron_core_ruby-' + IronCore.version + ')',
          :queue_name => 'default'
      }

      super('iron', 'mq', options, default_options, [:project_id, :token, :api_version, :queue_name])

      IronCore::Logger.error 'IronMQ', "Token is not set", IronCore::Error if @token.nil?

      check_id(@project_id, 'project_id')

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    def headers
      super.merge({'Authorization' => "OAuth #{@token}"})
    end

    def base_url
      "#{super}#{@api_version}/"
    end

    def queue(name)
      queues.get({:name => name})
    end

    def messages
      @messages ||= Messages.new(self)
    end

    def queues
      @queues ||= Queues.new(self)
    end
  end
end
