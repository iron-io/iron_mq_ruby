module Helpers
  def delete_queue(client, qname)
    client.delete_queue(qname)
  rescue Rest::HttpError => e
    raise e unless e.message.include? 'Queue not found'
  end

  def with_fields(entity, *fields, &block)
    fields.map do |f|
      field = entity.public_send(f.to_sym)

      block_given? && block.call(field)

      field
    end
  end

  def assert_response(resp, *keys)
    refute_nil resp
    assert_instance_of Hash, resp
    keys.each do |key|
      assert resp.member?(key), "key #{key} is not member of response"
    end
  end

  def make_subscribers(num)
    num.times.map { |n| {name: "sub-#{n}", url: "http://dev.iron.io/#{n}"} }
  end

  def make_messages_bodies(num)
    num.times.map { |n| "msg-#{n}" }
  end

  def make_messages_hashes(num)
    num.times.map { |n| {body: "msg-#{n}"} }
  end

  def assert_subscribers_equal(subs1, subs2)
    assert_arrays_of_hashes_equal subs1, subs2, 'subscribers must be equal'
  end

  def assert_alerts_equal(al1, al2)
    assert_arrays_of_hashes_equal al1, al2, 'alerts must be equal'
  end

  def assert_arrays_of_hashes_equal(arr1, arr2, msg = nil)
    assert_equal arr1.size, arr2.size, msg
    assert_equal normalise_hashes(arr1), normalise_hashes(arr2), msg
  end

  # keywordise keys of subscribers hashes and sort them by name
  def normalise_hashes(arr)
    arr
      .map { |sub| sub.reduce({}) { |r, (k, v)| r.update(k.to_sym => v) } }
      .sort! { |s1, s2| s1[:name] <=> s2[:name] }
  end
end
