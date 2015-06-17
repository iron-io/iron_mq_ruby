module IronClient
  # 
  class Push < BaseObject
    attr_accessor :retries, :retries_delay, :error_queue, :rate_limit, :subscribers
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'retries' => :'retries',
        
        # 
        :'retries_delay' => :'retries_delay',
        
        # 
        :'error_queue' => :'error_queue',
        
        # 
        :'rate_limit' => :'rate_limit',
        
        # 
        :'subscribers' => :'subscribers'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'retries' => :'int',
        :'retries_delay' => :'int',
        :'error_queue' => :'string',
        :'rate_limit' => :'int',
        :'subscribers' => :'array[QueueSubscriber]'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'retries']
        @retries = attributes[:'retries']
      end
      
      if attributes[:'retries_delay']
        @retries_delay = attributes[:'retries_delay']
      end
      
      if attributes[:'error_queue']
        @error_queue = attributes[:'error_queue']
      end
      
      if attributes[:'rate_limit']
        @rate_limit = attributes[:'rate_limit']
      end
      
      if attributes[:'subscribers']
        if (value = attributes[:'subscribers']).is_a?(Array)
          @subscribers = value
        end
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
