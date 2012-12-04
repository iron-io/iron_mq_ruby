
module IronMQ

  class ResponseBase

    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def [](key)
      raw[key]
    end

    def id
      raw["id"]
    end

    def msg
      raw["msg"]
    end

  end


end