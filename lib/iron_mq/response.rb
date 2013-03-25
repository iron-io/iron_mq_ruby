require 'ostruct'

module IronMQ

  class ResponseBase < OpenStruct
    def initialize(data, code = 200)
      super(data.merge(:code => code.to_i))
    end

    def [](key)
      send(key.to_s)
    end

    def raw
      res = stringify_keys(marshal_dump)
      # `code` is not part of response body
      res.delete("code")

      res
    end

    private

    def stringify_keys(hash)
      hash.keys.each { |k| hash[k.to_s] = hash.delete(k) }

      hash
    end
  end

end
