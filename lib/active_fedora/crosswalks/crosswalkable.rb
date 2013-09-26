module ActiveFedora
  module Crosswalks
    module Crosswalkable
      def crosswalk_fields
        @crosswalk_fields ||= []
      end
      def crosswalk(*args)
        args = args.first if args.respond_to? :first
        raise "Hash of options not given" unless args.kind_of?(Hash)
        args[:datastream] = self
        crosswalker = Crosswalker.new(args)
        crosswalker.validate!
        crosswalker.perform_crosswalk!
      end
    end
  end
end
