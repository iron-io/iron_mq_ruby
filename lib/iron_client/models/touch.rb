module IronClient
  # 
  class Touch < BaseObject
    attr_accessor :reservation_id, :timeout
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'reservation_id' => :'reservation_id',
        
        # optional. How many seconds new reservation will be valid. Defaults to queue&#39;s message_timeout option
        :'timeout' => :'timeout'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'reservation_id' => :'string',
        :'timeout' => :'string'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'reservation_id']
        @reservation_id = attributes[:'reservation_id']
      end
      
      if attributes[:'timeout']
        @timeout = attributes[:'timeout']
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
