module IronClient
  # 
  class DeleteMsg < BaseObject
    attr_accessor :id, :reservation_id, :subscriber_name
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'id' => :'id',
        
        # 
        :'reservation_id' => :'reservation_id',
        
        # 
        :'subscriber_name' => :'subscriber_name'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'id' => :'string',
        :'reservation_id' => :'string',
        :'subscriber_name' => :'string'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'id']
        @id = attributes[:'id']
      end
      
      if attributes[:'reservation_id']
        @reservation_id = attributes[:'reservation_id']
      end
      
      if attributes[:'subscriber_name']
        @subscriber_name = attributes[:'subscriber_name']
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
