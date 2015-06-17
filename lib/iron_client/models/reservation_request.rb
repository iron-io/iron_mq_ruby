module IronClient
  # 
  class ReservationRequest < BaseObject
    attr_accessor :n, :timeout, :wait, :delete
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # The maximum number of messages to get.\nNote: You may not receive all n messages on every request, the more sparse the queue, the less likely you are to receive all n messages.\n
        :'n' => :'n',
        
        # After timeout (in seconds), item will be placed back onto queue. You must delete the message from the queue to ensure it does not go back onto the queue.\n
        :'timeout' => :'timeout',
        
        # Time to long poll for messages, in seconds.\n
        :'wait' => :'wait',
        
        # 
        :'delete' => :'delete'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'n' => :'int',
        :'timeout' => :'int',
        :'wait' => :'int',
        :'delete' => :'boolean'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'n']
        @n = attributes[:'n']
      end
      
      if attributes[:'timeout']
        @timeout = attributes[:'timeout']
      end
      
      if attributes[:'wait']
        @wait = attributes[:'wait']
      end
      
      if attributes[:'delete']
        @delete = attributes[:'delete']
      end
      
    end

    # http://stackoverflow.com/questions/5030553/ruby-convert-object-to-hash
    def to_h
      hash = {}
      instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
      hash
    end
  end
end
