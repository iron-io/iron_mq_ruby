require 'iron_core'

module IronMQ
  # FIXME: read real version
  def self.version
    '2.0.0'
  end

  class Client < IronCore::Client
    AWS_US_EAST_HOST = 'mq-aws-us-east-1.iron.io'

    attr_accessor :queue_name

    def initialize(options={})
      super('mq', options, [:queue_name])

      load_from_hash(:scheme => 'https', :host => IronMQ::Client::AWS_US_EAST_HOST, :port => 443, :api_version => 1, :user_agent => 'iron_mq_ruby-' + IronMQ.version + ' (iron_core_ruby-' + IronCore.version + ')', :queue_name => 'default')

      if (not @token) || (not @project_id)
        IronCore::Logger.error 'IronMQ', 'Both token and project_id must be specified' 
        raise IronCore::IronError.new('Both token and project_id must be specified')
      end
    end

    def messages
      return Messages.new(self)
    end

    def queues
      return Queues.new(self)
    end
  end
end
