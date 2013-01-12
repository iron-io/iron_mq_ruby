
module IronMQ

  class ResponseBase

    attr_reader :raw, :code

    def initialize(raw, code=200)
      @raw = raw
      @code = code
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