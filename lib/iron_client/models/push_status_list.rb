module IronClient
  # 
  class PushStatusList < BaseObject
    attr_accessor :subscribers
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'subscribers' => :'subscribers'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'subscribers' => :'array[PushStatus]'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
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
