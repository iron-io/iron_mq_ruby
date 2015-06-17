module IronClient
  # 
  class MessagePostData < BaseObject
    attr_accessor :delay, :body, :push_headers
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'delay' => :'delay',
        
        # 
        :'body' => :'body',
        
        # 
        :'push_headers' => :'push_headers'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'delay' => :'int',
        :'body' => :'string',
        :'push_headers' => :'object'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'delay']
        @delay = attributes[:'delay']
      end
      
      if attributes[:'body']
        @body = attributes[:'body']
      end
      
      if attributes[:'push_headers']
        @push_headers = attributes[:'push_headers']
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
