module ActiveFedora
  module Crosswalks
    module Accessors
      class RelsExtAccessor < GenericAccessor
        def get_reader
          raise "Crosswalking from Rels-Ext not supported"
        end
        def get_writer
          raise "Crosswalking from Rels-Ext not supported."
        end
        def get_value
          FieldProxy.new(Array.wrap(datastream.model.relationships(field.to_sym)), self, field)
        end
        def set_value(*args)
          datastream.model.clear_relationship(field.to_sym)
          value = Array.wrap(args.last)
          value.each do |v|
            datastream.model.add_relationship(field.to_sym, v)
          end
        end
        alias_method :original_get_value, :get_value
        alias_method :original_set_value, :set_value
      end
    end
  end
end