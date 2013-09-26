class FieldProxy
  attr_accessor :array, :accessor, :field
  delegate *(Array.public_instance_methods - [:__send__, :__id__, :class, :object_id] + [:as_json]), :to => :array
  def initialize(array, accessor, field)
    self.array = array
    self.accessor = accessor
    self.field = field
  end
  def << (value)
    array << value
    accessor.set_value(field, array)
  end
end