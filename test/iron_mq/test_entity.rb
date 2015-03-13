require 'set'

gem 'minitest'
require 'minitest/autorun'

require 'iron_mq/entity'

class TestEntity < Minitest::Test
  def setup
    @klass = Class.new do
      include IronMQ::Entity

      define_fields :a, :b
      define_fields :z

      def initialize(payload = {})
        self.entity = payload
      end
    end

    @the_fields = Set.new([:a, :b, :z])
    @payload = {a: 'a copy of A', b: 'the B', z: 'Zee'}
  end

  def stringify_keys(hsh)
    hsh.reduce({}) { |m, (k, v)| m.update(k.to_s => v) }
  end

  def test_all_fields_defined
    assert_equal @the_fields, @klass.fields
  end

  def test_keywordise_keys_protected
    pl = stringify_keys @payload
    assert_equal @payload, @klass.new.send(:keywordise_keys, pl)
  end

  def test_keywordise_and_filter_fields_protected
    pl = @payload.merge(unknown: 'what?', not_defined: 'must not appear')
    assert_equal @payload, @klass.new.send(:keywordise_and_filter_fields, pl)

    pl = stringify_keys @payload
    assert_equal @payload, @klass.new.send(:keywordise_and_filter_fields, pl)

    pl = stringify_keys(@payload).merge(some: 'undef', other: 'filtered')
    assert_equal @payload, @klass.new.send(:keywordise_and_filter_fields, pl)
  end

  def test_all_methods_defined
    inst = @klass.new
    @the_fields.each { |f| assert_respond_to inst, f }
  end

  def all_fields_accepted_and_accessible(klass, payload)
    inst = klass.new(payload)
    payload.each do |f, v|
      assert_equal inst.public_send(f), v, "field #{f} is not accessible"
    end
  end

  def test_all_fields_accepted_and_accessible
    all_fields_accepted_and_accessible @klass, @payload
  end

  def test_must_warn_and_not_define_existing_method
    assert_output(nil, "field 'class' cannot be defined, " \
                       "because Class already has such method.\n") do
      @klass.define_fields :class
    end
  end
end

class TestEntityInherited < TestEntity
  def setup
    super

    @sklass = @klass
    @klass = Class.new(@sklass) do
      define_fields :new_field
    end

    @the_fields.add(:new_field)
    @payload.update(new_field: 'new data')
  end

  def test_base_class_fields_included
    assert @klass.fields.proper_superset?(@sklass.fields)
  end
end
