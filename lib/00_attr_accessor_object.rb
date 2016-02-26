class AttrAccessorObject

  def self.my_attr_accessor(*names)
    # ...
    #self == AttrAccessorObject (the class)
    names.each do |attribute|
      #self == AttrAccessorObject (the class)
      define_method(attribute) do
        #self == an instance of AttrAccessorObject
        getter = ('@' + attribute.to_s).to_sym
        self.instance_variable_get(getter)
      end

      setter = (attribute.to_s + :'='.to_s).to_sym
      define_method(setter) do |arg|
        self.instance_variable_set(('@' + attribute.to_s).to_sym, arg)
      end
      
    end

  end

  def name
    #self is instance
    self.instance_variable_get(getter)
  end

end
