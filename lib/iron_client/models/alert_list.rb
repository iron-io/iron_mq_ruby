module IronClient
  # 
  class AlertList < BaseObject
    attr_accessor :alerts
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'alerts' => :'alerts'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'alerts' => :'array[Alert]'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'alerts']
        if (value = attributes[:'alerts']).is_a?(Array)
          @alerts = value
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
