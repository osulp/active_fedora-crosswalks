module ActiveFedora
  module Crosswalks
    module Accessors
      class OmAccessor < GenericAccessor
        def get_reader
          raise "Crosswalking from OM not supported"
        end
        def get_writer
          raise "Crosswalking from OM not supported."
        end
        def get_value
          FieldProxy.new(datastream.send(:term_values, *field), self, field)
        end
        def set_value(*args)
          value = Array.wrap(args.last)
          datastream.send(:update_indexed_attributes, {field => value})
        end
        alias_method :original_get_value, :get_value
        alias_method :original_set_value, :set_value
      end
    end
  end
end