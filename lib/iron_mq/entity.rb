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

          define_method(field) { entity.dup[field] }
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

      def to_s
        entity.to_s
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
