module ActiveDynamic
  class AttributeDefinition

    attr_reader :label, :system_name, :is_vocabulary, :vocabulary, :column_type, :default, :help_text, :source_type, :is_required, :is_repeatable, :is_public

    def initialize(system_name, params = {})
      options = params.dup
      @name = (options.delete(:system_name) || system_name)
      @display_name = system_name.titleize
      @datatype = options.delete(:column_type)
      @value = options.delete(:default)
      @required = options.delete(:is_required) || false
      @is_vocabulary = options.delete(:is_vocabulary) || false
      @vocabulary = options.delete(:vocabulary)
      @help_text = options.delete(:help_text) || false
      @is_repeatable = options.delete(:is_repeatable) || false
      @is_public = options.delete(:is_public) || false

      # custom attributes from Provider
      options.each do |key, value|
        self.instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end

    def required?
      !!@required
    end

    def repeatable?
      !!@is_repeatable
    end

    def required?
      !!@required
    end

    def public?
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