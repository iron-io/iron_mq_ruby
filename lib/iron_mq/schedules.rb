
module IronMQ

  class Schedule < ResponseBase
    attr_reader :raw, :code

    def initialize(data)
      @raw = data
    end

    def name
      @raw['name']
    end

    def schedule
      @raw['schedule']
    end

    def url
      @raw['url']
    end

    def timezone
      @raw['timezone']
    end

  end

end
