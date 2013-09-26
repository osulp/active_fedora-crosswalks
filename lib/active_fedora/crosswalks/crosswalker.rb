module ActiveFedora
  module Crosswalks
    class Crosswalker
      include ActiveModel::Validations
      validates :parent, :field, :to, :presence => true
      validate :parent_has_datastream
      attr_accessor :parent, :datastream, :target_datastream, :field, :to
      def initialize(args)
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
      end

      def source_accessor
        @source_accessor ||= Accessors::GenericAccessor.new(datastream, field)
      end

      def target_accessor
        @target_accessor ||= Accessors::GenericAccessor.new(target_datastream, to)
      end

      protected

      def create_reader
        object, method, expected_args = source_accessor.get_reader
        crosswalker = self
        object.define_singleton_method(method) do |*args|
          puts "Expected Arguments in Reader: #{expected_args}"
          if !expected_args || args[0..-2] == expected_args || (args.last.kind_of?(Hash) && args.last.has_key?(expected_args))
            crosswalker.source_accessor.set_value(crosswalker.target_accessor.get_value)
          end
          crosswalker.target_accessor.get_value
        end
      end

      def create_writer
        object, method, expected_args = source_accessor.get_writer
        crosswalker = self
        object.define_singleton_method(method) do |*args|
          puts "Expected Arguments in Writer: #{expected_args}"
          if !expected_args || args[0..-2] == expected_args || (args.last.kind_of?(Hash) && args.last.has_key?(expected_args))
            result = super(args.last)
            crosswalker.target_accessor.set_value(result)
            return result
          end
        end
      end

      def parent_has_datastream
        errors.add(:parent, "does not have a datastream #{@target_datastream_key}") unless target_datastream
      end

    end
  end
end