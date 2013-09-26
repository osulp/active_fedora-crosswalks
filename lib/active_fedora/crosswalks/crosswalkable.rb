module ActiveFedora
  module Crosswalks
    module Crosswalkable
      def crosswalk(*args)
        args = args.first if args.respond_to? :first
        validate_parameters!(args)
        crosswalker = Crosswalker.new(args)
      end

      private

      def validate_parameters!(args)
        raise "crosswalk must specify an element as :field argument" unless args.kind_of?(Hash) && args.has_key?(:field)
        raise "crosswalk for '#{args[:field]}' must specify an element as :to argument" unless args.kind_of?(Hash) && args.has_key?(:to)
        raise "crosswalk for '#{args[:field]}' must specify a datastream as :in argument" unless args.kind_of?(Hash) && args.has_key?(:in)
      end
    end
  end
end
