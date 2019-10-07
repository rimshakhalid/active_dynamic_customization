module ActiveDynamic
  class FieldValuesDefinition
    attr_reader :field_id, :field_name, :value, :vocab_value

    def initialize(params = {})
      options = params.dup
      @field_id = options.delete(:field_id)
      @field_name = options.delete(:field_name)
      @value = options.delete(:value) || ''
      @vocab_value = options.delete(:vocab_value) || ''

      # custom attributes from Provider
      options.each do |key, value|
        self.instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end
  end
end