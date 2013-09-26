module ActiveFedora
  module Crosswalks
    module Accessors
      class GenericAccessor
        attr_accessor :datastream, :field
        def self.new(datastream, field)
          if self.to_s.include?("GenericAccessor")
            if datastream.kind_of?(ActiveFedora::RelsExtDatastream)
              return RelsExtAccessor.new(datastream, field)
            end
            if datastream.kind_of?(ActiveFedora::OmDatastream)
              return OmAccessor.new(datastream, field)
            end
          end
          super
        end
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
        def set_value(*args)
          value = args.last
          datastream.send("#{field.to_s}=",value)
        end
      end
    end
  end
end