module IronMQ
  class Queues

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def path(options={})
      path = "projects/#{@client.project_id}/queues"
      if options[:name]
        path << "/#{CGI::escape(options[:name])}"
      end
      path
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
      res = @client.parse_response(@client.get("#{path(options)}"))
      return Queue.new(@client, res)
    end

    # Update a queue
    # options:
    #  :name => if not specified, will use global queue name
    #  :subscriptions => url's to subscribe to
    def post(options={})
      options[:name] ||= @client.queue_name
      res = @client.parse_response(@client.post(path(options), options))
      res
      p res

    end


  end

  class Queue

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
      load_queue
    end

    # Used if lazy loading
    def load_queue
      q = @client.queues.get(:name => name)
      @client.logger.debug "GOT Q: " + q.inspect
      @data = q.raw
      q
    end

    def clear()
      @client.queues.clear(:name => name)
    end

    def delete_queue()
      @client.queues.delete(:name=>name)
    end

    def size
      return raw["size"] if raw["size"]
      return @size if @size
      q = load_queue()
      @size = q.size
      @size
    end

    def total_messages
      return raw["total_messages"] if raw["total_messages"]
      return @total_messages if @total_messages
      q = load_queue()
      @total_messages = q.total_messages
      @total_messages
    end

    def post(body, options={})
      @client.messages.post(body, options.merge(:queue_name => name))
    end

    def get(options={})
      @client.messages.get(options.merge(:queue_name => name))
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
        p options
        msg = get(options)
        if msg.nil?
          if options[:break_if_nil]
            break
          else
            sleep sleep_duration
          end
        end
        yield msg
        msg.delete
      end
    end

    def delete(id, options={})
      @client.messages.delete(id, options.merge(:queue_name => name))
    end

  end

end

