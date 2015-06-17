module IronClient
  # 
  class TouchResponse < BaseObject
    attr_accessor :reservation_id, :msg
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'reservation_id' => :'reservation_id',
        
        # 
        :'msg' => :'msg'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'reservation_id' => :'string',
        :'msg' => :'string'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'reservation_id']
        @reservation_id = attributes[:'reservation_id']
      end
      
      if attributes[:'msg']
        @msg = attributes[:'msg']
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
