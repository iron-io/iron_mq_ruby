module IronClient
  # 
  class Message < BaseObject
    attr_accessor :id, :body, :reservation_id, :reserved_count
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'id' => :'id',
        
        # 
        :'body' => :'body',
        
        # 
        :'reservation_id' => :'reservation_id',
        
        # 
        :'reserved_count' => :'reserved_count'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'id' => :'string',
        :'body' => :'string',
        :'reservation_id' => :'string',
        :'reserved_count' => :'int'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'id']
        @id = attributes[:'id']
      end
      
      if attributes[:'body']
        @body = attributes[:'body']
      end
      
      if attributes[:'reservation_id']
        @reservation_id = attributes[:'reservation_id']
      end
      
      if attributes[:'reserved_count']
        @reserved_count = attributes[:'reserved_count']
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
