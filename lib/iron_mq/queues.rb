require 'cgi'
require 'iron_mq/subscribers'

module IronMQ
  class Queues

    attr_accessor :client # is attr_reader better?

    def initialize(client)
      @client = client
    end

    def self.path(options)
      path = "projects/#{options[:project_id]}/queues"
      name = options[:name] || options[:queue_name]
      path += "/#{CGI::escape(name)}" if name
      path
    end

    def path(options = {})
      options[:project_id] = @client.project_id
      Queues.path(options)
    end

    def list(options = {})
      options = remove_queue_name_option(options)

      res = @client.parse_response(@client.get("#{path(options)}", options))
      # returns list of evaluated queues
      res.each_with_object([]) { |q, ret| ret << Queue.new(@client, q) }
    end

    alias_method :all, :list

    # FIXME: To make better IronMQ API reflection
    #        methods `clear`, `delete`, `get` must check that `options[:name]` is specified.
    #        Becase IronMQ API has only one request (list of queues)
    #          GET /projects/{Project ID}/queues
    #        where queue name is not used
    #
    #        Maybe not bad idea is to re-define the methods like:
    #          def clear(queue_name, options = {})

    def clear(options = {})
      # TODO: make common logging system, gem-wide, like
      #   with_logging(level) do |log|
      #     log "Something"
      #     do "Anything"
      #     log "Again"
      #   end
      @client.logger.debug "Clearing queue #{options[:name]}"
      r1 = @client.parse_response(@client.post("#{path(options)}/clear", options))
      @client.logger.debug "Clear result: #{r1}"
      r1
    end


    def delete(options = {})
      @client.logger.debug "Deleting queue #{options[:name]}"
      r1 = @client.parse_response(@client.delete("#{path(options)}", options))
      @client.logger.debug "Delete result: #{r1}"
      r1
    end

    # GET /projects/{Project ID}/queues/{Queue Name}
    def info(queue_name, options = {})
      opts = options.merge({:queue_name => queue_name})
      @client.parse_response(@client.get("#{path(opts)}"))
    end

    # options:
    #  :name => can specify an alternative queue name
    def get(options = {})
      # What global queue is? Does it reflect any API feature?
      qname = options[:name] || @client.queue_name
      resp = info(qname, options)

      Queue.new(@client, resp)
    end

    # Update a queue
    # options:
    #  :name => if not specified, will use global queue name
    #  :subscribers => url's to subscribe to
    #  :push_type => multicast (default) or unicast.
    def post(options = {})
      options[:name] ||= @client.queue_name
      @client.parse_response(@client.post(path(options), options))
    end

    private

    # Make sure it is no parameter which `path` method could evaluate as queue name
    def remove_queue_name_option(options)
      [:name, 'name', :queue_name, 'queue_name'].each { |key| options.delete(key) }
      options
    end

  end

  class Queue

    attr_reader :client

    def initialize(client, queue_info)
      @client = client
      @info = queue_info
      # @info = Queues.post(:name => @info["name"]) unless @info["id"] # creates queue on backend
    end

    def info
      begin
        # It does not require queue evaluation, get info Hash response from IronMQ API
        @info = @client.queues.info(name)
      rescue Rest::HttpError
        @info
      end
    end

    alias_method :raw, :info # backward compatibility

    def reload # backward compatibility
      info
    end

    def [](key)
      info[key.to_s]
    end

    def id
      info["id"]
    end

    def name
      # queue name does not require reloading, exists in new queue, ever constant
      @info["name"]
    end

    def size
      info["size"]
    end

    def total_messages
      info["total_messages"]
    end

    def subscribers
      info["subscribers"]
    end

    def push_type
      info["push_type"]
    end

    def new?
      id.nil?
    end

    def push_queue?
      !info["push_type"].nil?
    end

    def clear
      @client.queues.clear(:name => name)
    end

    # FIXME: This method must be named `delete`. 
    #        Name is kept for backward compatibility with previous version of gem.
    def delete_queue
      @client.queues.delete(:name => name)
    end

    # Updates the queue object
    #  :subscribers => url's to subscribe to
    #  :push_type => multicast (default) or unicast.
    def update(options)
      @client.queues.post(options.merge(:name => name))
    end

    alias_method :update_queue, :update

    def add_subscriber(subscriber_hash, options = {})
      res = @client.post("#{@client.queues.path(:name => name)}/subscribers",
                         :subscribers => [subscriber_hash])

      @client.parse_response(res)
    end

    def remove_subscriber(subscriber_hash)
      res = @client.delete("#{@client.queues.path(:name => name)}/subscribers",
                           {:subscribers => [subscriber_hash]},
                           {"Content-Type" => @client.content_type})

      @client.parse_response(res)
    end

    def post(body, options = {})
      @client.messages.post(body, options.merge(:name => name))
    end

    alias_method :post_message, :post

    def get(options = {})
      @client.messages.get(options.merge(:name => name))
    end

    alias_method :get_message, :get

    # FIXME: This method name must be named `delete_message`.
    #        Name is kept for backward compatibility with previous version of gem
    def delete(id, options = {})
      @client.messages.delete(id, options.merge(:name => name))
    end

    alias_method :delete_message, :delete

    # This will continuously poll for a message and pass it to the block. For example:
    #
    #     queue.poll { |msg| puts msg.body }
    #
    # options:
    # - :sleep_duration=>seconds => time between polls if msg is nil. default 1.
    # - :break_if_nil=>true/false => if true, will break if msg is nil (ie: queue is empty)
    def poll(options = {}, &blk)
      sleep_duration = options[:sleep_duration] || 1
      
      while true
        msg = get(options)
        if msg.nil?
          options[:break_if_nil] ? break : sleep(sleep_duration)
        else
          yield msg
          msg.delete
        end
      end
    end

    def messages
      Messages.new(client, self)
    end

  end

end

