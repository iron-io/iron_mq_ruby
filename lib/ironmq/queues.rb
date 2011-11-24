module IronMQ
  class Queues

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def path(options={})
      path = "/projects/#{@client.project_id}/queues"
    end

    # options:
    #  :name => can specify an alternative queue name
    def get(options={})
	    res, status = @client.get("#{path(options)}/#{options[:name]}")
	    return Queue.new(self, res)
    end


  end

  class Queue

    def initialize(queues, res)
      @queues = queues
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

    def size
      raw["size"]
	end

    # def delete
      # @messages.delete(self.id)
    # end
  end

end

