# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml
require_relative 'test_base'

class QuickRun < TestBase
 
 def setup
  super
   @client.queue_name = 'ironmq-gem-quick'
end

  def test_basics
    res = @client.messages.post("hello world!")
    p res

    res = @client.messages.get()
    p res

    res = @client.messages.delete(res["id"])
    p res

    res = @client.messages.get()
    p res
   
  end

 
end

