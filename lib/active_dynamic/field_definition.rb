module ActiveDynamic
  class FieldDefinition

    attr_reader :label, :system_name, :is_vocabulary, :vocabulary, :column_type, :default, :help_text, :source_type, :is_required, :is_repeatable, :is_public, :is_custom, :field_value, :field_vocab

    def initialize(system_name, params = {})
      options = params.dup
      @system_name = (options.delete(:system_name) || system_name)
      @label = system_name.titleize
      @column_type = options.delete(:column_type)
      @default = options.delete(:default)
      @is_required = options.delete(:is_required) || false
      @is_vocabulary = options.delete(:is_vocabulary) || false
      @vocabulary = options.delete(:vocabulary)
      @help_text = options.delete(:help_text) || false
      @is_repeatable = options.delete(:is_repeatable) || false
      @is_public = options.delete(:is_public) || true
      @is_custom = options.delete(:is_custom) || false


      # custom attributes from Provider
      options.each do |key, value|
        self.instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end

    def is_required?
      !!@is_required
    end

    def is_repeatable?
      !!@is_repeatable
    end


    def is_public?
      !!@is_public
    end

    def has_vocabulary?
      !!@is_vocabulary
    end

    def vocabulary
      @vocabulary
    end

  end
end