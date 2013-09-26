module ActiveFedora
  module Crosswalks
    module Crosswalkable
      # Override content so when it's called it performs crosswalks first.
      def content
        crosswalkers.each do |crosswalker|
          crosswalker.source_accessor.get_value
        end
        super
      end
      def crosswalk_fields
        @crosswalk_fields ||= []
      end
      def crosswalkers
        @crosswalkers ||= []
      end
      def crosswalk(*args)
        args = args.first if args.respond_to? :first
        raise "Hash of options not given" unless args.kind_of?(Hash)
        args[:datastream] = self
        crosswalker = Crosswalker.new(args)
        crosswalker.validate!
        crosswalker.perform_crosswalk!
        self.crosswalkers << crosswalker
      end
    end
  end
end
