module IronClient
  # 
  class Subscriber < BaseObject
    attr_accessor :name, :url, :headers
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'name' => :'name',
        
        # 
        :'url' => :'url',
        
        # 
        :'headers' => :'headers'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'name' => :'string',
        :'url' => :'string',
        :'headers' => :'object'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'name']
        @name = attributes[:'name']
      end
      
      if attributes[:'url']
        @url = attributes[:'url']
      end
      
      if attributes[:'headers']
        @headers = attributes[:'headers']
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
