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
          :user_agent => 'iron_mq_ruby-' + IronMQ::VERSION + ' (iron_core_ruby-' + IronCore.version + ')'
      }

      @queue_options = {:cache_queue_info => true}.merge(cut_queue_options(options))

      super('iron', 'mq', options, default_options, [:project_id, :token, :api_version])

      IronCore::Logger.error 'IronMQ', "Token is not set", IronCore::Error if @token.nil?

      check_id(@project_id, 'project_id')

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    def headers
      super.merge({'Authorization' => "OAuth #{@token}"})
    end

    def base_url
      @base_url = "#{super}#{@api_version}/projects/#{@project_id}/queues"
    end

    def queues_list(options = {})
      is_raw = [options.delete(:raw),
                options.delete('raw')].compact.first

      qopts = @queue_options.merge(cut_queue_options(options))

      response = parse_response(get('', options)) # GET base_url
      # returns list of evaluated queues
      if is_raw
        response.map{ |q_info| ResponseBase.new(q_info) }
      else
        response.map{ |q_info| Queue.new(self, q_info["name"], qopts) }
      end
    end

    alias_method :list, :queues_list
    alias_method :all, :queues_list

    def queues_get(name, opts = {})
      IronMQ::Queue.new(self, name, @queue_options.merge(cut_queue_options(opts)))
    end

    alias_method :queue, :queues_get

    # Backward compatibility for
    #   client.queues.get(:name => "my_queue")
    #   client.queues.get("name" => "my_queue")
    def get(*args)
      if args.size == 1 && args[0].is_a?(Hash)
        queue_name = (args[0][:name] || args[0]["name"]).to_s
        queue_name.empty? ? super : queues_get(queue_name)
      else
        super
      end
    end

    # Backward compatibility, adds possibility to call
    #   client.queues.all
    #   client.queues.list
    #   client.queues.queue(name)
    def queues
      self
    end

    private

    def cut_queue_options(opts)
      qopts = {}

      cache_info = [opts.delete(:cache_queue_info),
                    opts.delete('cache_queue_info')].compact.first
      qopts[:cache_queue_info] = cache_info unless cache_info.nil?

      qopts
    end
  end

end
