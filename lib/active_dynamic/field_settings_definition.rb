module ActiveDynamic
  class FieldSettingsDefinition
    attr_reader :field_id, :is_visible, :is_tomstone

    def initialize(params = {})
      options = params.dup
      @field_id = options.delete(:field_id)
      @is_visible = options.delete(:is_visible) || true
      @is_tomstone = options.delete(:is_tomstone) || false

      # custom attributes from Provider
      options.each do |key, value|
        self.instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end

    def is_visible?
      !!@is_visible
    end

    def is_tomstone?
      !!@is_tomstone
    end
  end
end