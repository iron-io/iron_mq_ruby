module IronClient
  # 
  class PushStatus < BaseObject
    attr_accessor :subscriber_name, :retries_remaining, :retries_total, :status_code, :msg, :url, :last_try_at
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'subscriber_name' => :'subscriber_name',
        
        # 
        :'retries_remaining' => :'retries_remaining',
        
        # 
        :'retries_total' => :'retries_total',
        
        # 
        :'status_code' => :'status_code',
        
        # 
        :'msg' => :'msg',
        
        # 
        :'url' => :'url',
        
        # 
        :'last_try_at' => :'last_try_at'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'subscriber_name' => :'string',
        :'retries_remaining' => :'int',
        :'retries_total' => :'int',
        :'status_code' => :'int',
        :'msg' => :'string',
        :'url' => :'string',
        :'last_try_at' => :'string'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'subscriber_name']
        @subscriber_name = attributes[:'subscriber_name']
      end
      
      if attributes[:'retries_remaining']
        @retries_remaining = attributes[:'retries_remaining']
      end
      
      if attributes[:'retries_total']
        @retries_total = attributes[:'retries_total']
      end
      
      if attributes[:'status_code']
        @status_code = attributes[:'status_code']
      end
      
      if attributes[:'msg']
        @msg = attributes[:'msg']
      end
      
      if attributes[:'url']
        @url = attributes[:'url']
      end
      
      if attributes[:'last_try_at']
        @last_try_at = attributes[:'last_try_at']
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
