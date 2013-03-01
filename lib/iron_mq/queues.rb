require 'cgi'
require 'iron_mq/subscribers'

module IronMQ
  class Queues

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def self.path(options)
      path = "projects/#{options[:project_id]}/queues"
      name = options[:name] || options[:queue_name] || options['queue_name']
      if name
        path << "/#{CGI::escape(name)}"
      end
      path
    end

    def path(options={})
      options[:project_id] = @client.project_id
      Queues.path(options)
    end

    def list(options={})
      ret = []
      r1 = @client.get("#{path(options)}", options)
      #p r1
      res = @client.parse_response(r1)
      res.each do |q|
        #p q
        q = Queue.new(@client, q)
        ret << q
      end
      ret
    end

    def clear(options={})
      @client.logger.debug "Clearing queue #{options[:name]}"
      r1 = @client.post("#{path(options)}/clear", options)
      @client.logger.debug "Clear result: #{r1}"
      r1
    end

    def delete(options={})
      @client.logger.debug "Deleting queue #{options[:name]}"
      r1 = @client.delete("#{path(options)}", options)
      @client.logger.debug "Delete result: #{r1}"
      r1
    end

    # options:
    #  :name => can specify an alternative queue name
    def get(options={})
      options[:name] ||= @client.queue_name
      r = @client.get("#{path(options)}")
      #puts "HEADERS"
      #p r.headers
      res = @client.parse_response(r)
      return Queue.new(@client, res)
    end

    # Update a queue
    # options:
    #  :name => if not specified, will use global queue name
    #  :subscribers => url's to subscribe to
    #  :push_type => multicast (default) or unicast.
    def post(options={})
      options[:name] ||= @client.queue_name
      res = @client.parse_response(@client.post(path(options), options))
      #p res
      res
    end


  end

  class Queue

    attr_reader :client

    def initialize(client, res)
      @client = client
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

    def name
      raw["name"]
    end

    def reload
      load_queue(:force => true)
    end

    def messages
      raw["messages"]
    end

    # Used if lazy loading
    def load_queue(options={})
      return if @loaded && !options[:force]
      q = @client.queues.get(:name => name)
      @client.logger.debug "GOT Q: " + q.inspect
      @data = q.raw
      @loaded = true
      q
    end

    def clear()
      @client.queues.clear(:name => name)
    end

    def delete_queue()
      @client.queues.delete(:name => name)
    end

    # Updates the queue object
    #  :subscribers => url's to subscribe to
    #  :push_type => multicast (default) or unicast.
    def update_queue(options)
      @client.queues.post(options.merge(:name => name))
    end

    def size
      load_queue()
      return raw["size"]
    end

    def total_messages
      load_queue()
      return raw["total_messages"]
    end

    def push_type
      load_queue()
      return raw["push_type"]
    end

    def subscribers
      load_queue()
      return raw["subscribers"]
    end

    def add_subscriber(subscriber_hash, options={})
      res = @client.post("#{@client.queues.path(:name => name)}/subscribers", :subscribers => [subscriber_hash])
      res = @client.parse_response(res)
      #p res
      res
    end

    def remove_subscriber(subscriber_hash)
      res = @client.delete("#{@client.queues.path(:name => name)}/subscribers", {:subscribers => [subscriber_hash]}, {"Content-Type"=>@client.content_type})
      res = @client.parse_response(res)
      #p res
      res
    end

    def post(body, options={})
      @client.messages.post(body, options.merge(:queue_name => name))
    end

    def get(options={})
      @client.messages.get(options.merge(:queue_name => name))
    end

    def delete(id, options={})
      @client.messages.delete(id, options.merge(:queue_name => name))
    end


    # This will continuously poll for a message and pass it to the block. For example:
    #
    #     queue.poll { |msg| puts msg.body }
    #
    # options:
    # - :sleep_duration=>seconds => time between polls if msg is nil. default 1.
    # - :break_if_nil=>true/false => if true, will break if msg is nil (ie: queue is empty)
    def poll(options={}, &blk)
      sleep_duration = options[:sleep_duration] || 1
      while true
        #p options
        msg = get(options)
        if msg.nil?
          if options[:break_if_nil]
            break
          else
            sleep sleep_duration
          end
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

