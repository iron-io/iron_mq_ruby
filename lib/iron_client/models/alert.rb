module IronClient
  # 
  class Alert < BaseObject
    attr_accessor :id, :type, :queue, :trigger, :snooze, :last_triggered_at
    # attribute mapping from ruby-style variable name to JSON key
    def self.attribute_map
      {
        
        # 
        :'id' => :'id',
        
        # 
        :'type' => :'type',
        
        # 
        :'queue' => :'queue',
        
        # 
        :'trigger' => :'trigger',
        
        # 
        :'snooze' => :'snooze',
        
        # 
        :'last_triggered_at' => :'last_triggered_at'
        
      }
    end

    # attribute type
    def self.swagger_types
      {
        :'id' => :'string',
        :'type' => :'string',
        :'queue' => :'string',
        :'trigger' => :'int',
        :'snooze' => :'int',
        :'last_triggered_at' => :'int'
        
      }
    end

    def initialize(attributes = {})
      return if !attributes.is_a?(Hash) || attributes.empty?

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'id']
        @id = attributes[:'id']
      end
      
      if attributes[:'type']
        @type = attributes[:'type']
      end
      
      if attributes[:'queue']
        @queue = attributes[:'queue']
      end
      
      if attributes[:'trigger']
        @trigger = attributes[:'trigger']
      end
      
      if attributes[:'snooze']
        @snooze = attributes[:'snooze']
      end
      
      if attributes[:'last_triggered_at']
        @last_triggered_at = attributes[:'last_triggered_at']
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
