require 'set'

module IronMQ
  module Entity
    def self.included(base)
      base.instance_variable_set(:@fields, Set.new)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      attr_reader :fields

      def define_fields(*list)
        list.map(&:to_sym).each do |field|
          if method_defined?(field)
            unless fields.include?(field)
              warn "field '#{field}' cannot be defined, " \
                   "because #{self.class} already has such method."
            end

            next
          end

          define_method(field) { entity[field] }
          fields.add(field)
        end

        nil
      end

      def inherited(subcls)
        subcls.instance_variable_set(:@fields, fields.dup)
      end
    end

    module InstanceMethods
      def to_h
        entity.dup
      end

      protected

      def entity
        @entity ||= {}
      end

      def entity=(hash)
        @entity = keywordise_and_filter_fields(hash)
      end

      def keywordise_keys(hash)
        hash.reduce({}) do |memo, (key, value)|
          v = case value
              when Hash
                keywordise_keys value
              when Array # only top level look up
                value.map { |v| v.is_a?(Hash) ? keywordise_keys(v) : v }
              else
                value
              end
          memo.update(key.to_sym => v)
        end
      end

      def keywordise_and_filter_fields(hash)
        keywordise_keys(hash).select { |k, _| self.class.fields.include? k }
      end
    end
  end
end

# class T
#   include IronMQ::Entity

#   define_fields :a, :b
#   define_fields :a, :name

#   def initialize(opts = {})
#     self.entity = opts
#   end
# end

# class X < T
#   define_fields :x, :class
# end

# t = T.new(a: 'the A', b: 'a B', z: 'Zee')
# puts "T.fields = '#{T.fields.inspect}'"
# puts "t.a = '#{t.a}', t.b = '#{t.b}', t.name = '#{t.name}'"

# x = X.new(a: 'a copy of a', name: 'the X', x: 'value of X')
# puts "X.fields = '#{X.fields.inspect}'"
# puts "x.a = '#{x.a}', x.b = '#{x.b}', x.name = '#{x.name}', x.x = '#{x.x}'"
