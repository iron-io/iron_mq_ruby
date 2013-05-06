require 'ostruct'

module IronMQ


  class ResponseBase
    attr_reader :raw, :code

    def initialize(data, code = 200)
      @raw = data
      @code = code
      #super(data.merge(:code => code.to_i))
    end

    def id
      @raw["id"]
    end

    def [](key)
      @raw[key]
    end

    def msg
      @raw["msg"]
    end
    #
    #def raw
    #  if @raw.nil?
    #    @raw = call_api_and_parse_response(:get, "", {}, false)
    #  end
    #  #res = stringify_keys(marshal_dump)
    #  ## `code` is not part of response body
    #  #res.delete("code")
    #  #
    #  #res
    #  @raw
    #end

    private

    def stringify_keys(hash)
      hash.keys.each { |k| hash[k.to_s] = hash.delete(k) }

      hash
    end
  end

end
