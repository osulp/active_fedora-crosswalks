module ActiveFedora
  module Crosswalks
    module Accessors
      class GenericAccessor
        attr_accessor :datastream, :field
        def initialize(datastream, field)
          @datastream = datastream
          @field = field
        end
        def get_reader
          return datastream, field, nil
        end
        def get_writer
          return datastream, "#{self.field}=", nil
        end
        def get_value
          FieldProxy.new(Array.wrap(datastream.send(field.to_s)), self, field)
        end
        def set_value(value)
          datastream.send("#{field.to_s}=",value)
        end
      end
    end
  end
end