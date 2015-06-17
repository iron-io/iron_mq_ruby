module IronClient
  # 
  class MessagesRequest < BaseObject
    attr_accessor :n
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # \&quot;The maximum number of messages to peek.\&quot; \&quot;Note: You may not receive all n messages on every request, the more sparse the queue, the less likely you are to receive all n messages.\&quot;\n
        :'n' => :'n'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'n' => :'int'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'n']
        @n = attributes[:'n']
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
