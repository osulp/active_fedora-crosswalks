module ActiveFedora
  module Crosswalks
    class Crosswalker
      include ActiveModel::Validations
      validates :parent, :field, :to, :presence => true
      validate :parent_has_datastream
      attr_accessor :parent, :datastream, :target_datastream, :field, :to, :transform, :reverse_transform
      def initialize(args)
        @transform = args.delete(:transform)
        @reverse_transform = args.delete(:reverse_transform)
        unless transform && reverse_transform || (!transform && !reverse_transform)
          raise "If a transform is provided, then a reverse transform must be as well."
        end
        @datastream = args.delete(:datastream)
        @parent = @datastream.digital_object if @datastream
        @field = args.delete(:field)
        @to = args.delete(:to)
        @target_datastream_key = args.delete(:in).to_s
        @target_datastream = parent.datastreams[@target_datastream_key] if parent.datastreams.has_key?(@target_datastream_key)
      end

      def validate!
        unless self.valid?
          errors.full_messages.each do |error|
            raise error
          end
        end
      end

      def perform_crosswalk!
        datastream.crosswalk_fields << field
        create_reader
        create_writer
        sync_values
      end

      def source_accessor
        @source_accessor ||= Accessors::GenericAccessor.new(datastream, field)
      end

      def target_accessor
        @target_accessor ||= Accessors::GenericAccessor.new(target_datastream, to)
      end

      def sync_values(opts={})
        current_source_values = Array.wrap(source_accessor.original_get_value)
        current_target_values = perform_transform(Array.wrap(target_accessor.original_get_value))
        combined = current_source_values | current_target_values
        combined = current_source_values if opts[:force_target]
        source_accessor.original_set_value(combined)
        target_accessor.original_set_value(perform_reverse_transform(combined))
      end

      protected

      def perform_transform(values)
        values.map!{|x| transform.call(x)} if transform
        return values
      end

      def perform_reverse_transform(values)
        values.map!{|x| reverse_transform.call(x)} if reverse_transform
        return values
      end

      def create_reader
        object, method, expected_args = source_accessor.get_reader
        crosswalker = self
        object.singleton_class.class_eval do
          alias_method "unstubbed_#{method}".to_sym, method.to_sym
        end
        object.define_singleton_method(method) do |*args|
          crosswalker.sync_values
          FieldProxy.new(crosswalker.source_accessor.original_get_value, crosswalker.source_accessor, crosswalker.source_accessor.field)
        end
      end

      def create_writer
        object, method, expected_args = source_accessor.get_writer
        crosswalker = self
        object.singleton_class.class_eval do
          alias_method "unstubbed_#{method}".to_sym, method.to_sym
        end
        object.define_singleton_method(method) do |*args|
          super(*args)
          crosswalker.sync_values(:force_target => true)
          FieldProxy.new(crosswalker.source_accessor.get_value, crosswalker.source_accessor, crosswalker.source_accessor.field)
        end
      end

      def parent_has_datastream
        errors.add(:parent, "does not have a datastream #{@target_datastream_key}") unless target_datastream
      end

    end
  end
end