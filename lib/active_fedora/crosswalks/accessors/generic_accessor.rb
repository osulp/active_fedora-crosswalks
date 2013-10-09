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
        def original_get_value
          if datastream.respond_to?("unstubbed_#{self.field}")
            FieldProxy.new(Array.wrap(datastream.send("unstubbed_#{self.field}")), self, field)
          else
            get_value
          end
        end
        def set_value(*args)
          value = args.last
          datastream.send("#{field.to_s}=",value)
        end
        def original_set_value(*args)
          value = args.last
          if datastream.respond_to?("unstubbed_#{self.field}=")
            datastream.send("unstubbed_#{self.field}=",value)
          else
            set_value(value)
          end
        end
      end
    end
  end
end