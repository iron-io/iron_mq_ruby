require 'yaml'

require 'iron_core'

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

    def url
      super + @api_version.to_s + '/'
    end

    def queue(name)
      return Queue.new(self, {"name"=>name})
    end


    def messages
      return Messages.new(self)
    end

    def queues
      return Queues.new(self)
    end

    def check_id(id, name = 'id', length = 24)
      if (not id.is_a?(String)) || id.length != length
        IronCore::Logger.error 'IronMQ', "Expecting #{length} symbol #{name} string", IronCore::Error
      end
    end
  end
end
