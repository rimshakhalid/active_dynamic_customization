module ActiveDynamic
  module HasDynamicAttributes
    extend ActiveSupport::Concern

    included do
      has_many :field_settings,
               autosave: true,
               dependent: :destroy
      has_many :field_values,
               autosave: true,
               dependent: :destroy
      before_save :save_fields, :save_settings, :save_values
      after_save :update_ids
    end

    class_methods do
      def where_dynamic(options)
        query = joins(:active_dynamic_attributes)

        options.each do |prop, value|
          query = query.where(active_dynamic_attributes: {
            name: prop,
            value: value
          })
        end

        query
      end
    end

    def dynamic_attributes
      attrs = {}
      if persisted? && any_dynamic_attributes?
        if should_resolve_persisted?
          attrs['fields'] = resolve_combined
        else
          attrs['fields'] = resolve_from_db
        end
      else
        attrs['fields'] = resolve_from_provider
      end
      setting = get_settings(attrs['fields'])
      attrs['settings'] = setting[0]
      attrs['fields'] = setting[1]
      attrs['values'] = get_dynamic_values(setting[0][self.class.name])
      attrs
    end

    def dynamic_attributes_loaded?
      @dynamic_attributes_loaded ||= false
    end

    def respond_to?(method_name, include_private = false)
      if super
        true
      else
        load_dynamic_attributes unless dynamic_attributes_loaded?
        dynamic_attributes['fields'].find { |attr| attr.system_name == method_name.to_s.delete('=') }.present?
      end
    end

    def method_missing(method_name, *arguments, &block)
      if dynamic_attributes_loaded?
        super
      else
        load_dynamic_attributes
        send(method_name, *arguments, &block)
      end
    end

    def create_dynamic(new_field)
      field_def = ActiveDynamic::FieldDefinition.new(new_field[:system_name], new_field)
      field = ActiveDynamic::Field.create(field_def.as_json)
      field.save
      current = dynamic_attributes['settings']
      current[field.source_type] << JSON.parse({field_id: field.id, is_visible: true, is_tomstone: false}.to_json)
      update_field_settings(current[field.source_type], field.source_type)
      # latest = {system_name: 'agent', is_custom: true, source_type: 'CollectionResource', column_type: 4}
    end

    def delete_dynamic(field)
      current = dynamic_attributes['settings']
      index = search(current[field.source_type], 'field_id', field.id)
      if index
        current[field.source_type].delete_at(index)
      end
      update_field_settings(current[field.source_type], field.source_type)
      ActiveDynamic::Field.delete(field.id)
      # latest = {system_name: 'agent1', is_custom: true, source_type: 'CollectionResource', column_type: 4}
    end

    def update_field_settings(new_settings, type=nil)
      ## TODO manage for collection resource, update settings of specific type
      current = dynamic_attributes['settings']
      if type.nil?
        current[self.class.name] = new_settings
      else
        current[type] = new_settings
      end
      @field_setting = ActiveDynamic::Settings.find_or_initialize_by(customizable_id: self.id, customizable_type: self.class.name)
      @field_setting.update({settings: current.to_json})
    end

    private

    def should_resolve_persisted?
      value = ActiveDynamic.configuration.resolve_persisted
      case value
      when TrueClass, FalseClass
        value
      when Proc
        value.call(self)
      else
        raise "Invalid configuration for resolve_persisted. Value should be Bool or Proc, got #{value.class}"
      end
    end

    def any_dynamic_attributes?
      if self.get_dynamic_initializer[:field_types].nil?
        ActiveDynamic::Field.where(source_type: self.class.name).any?
      else
        ActiveDynamic::Field.where(source_type: self.get_dynamic_initializer[:field_types]).any?
      end
    end

    def resolve_combined
      attributes = resolve_from_db
      resolve_from_provider.each do |attribute|
        attributes << ActiveDynamic::Field.find_or_initialize_by(attribute.as_json)
      end
      attributes
    end

    def resolve_from_db
      if self.get_dynamic_initializer[:field_types].nil?
       fields = ActiveDynamic::Field.where(source_type: self.class.name, is_custom: false)
      else
       fields = ActiveDynamic::Field.where(source_type: self.get_dynamic_initializer[:field_types], is_custom: false)
      end
      fields
    end

    def resolve_from_provider
      ## TODO: if fields settings are already set in case of collection resource
      fields = ActiveDynamic.configuration.provider_class.new(self).call
      attributes = []
      fields.each do |attribute|
        field = ActiveDynamic::Field.find_or_initialize_by(attribute.as_json)
        field.save
        attributes << field
      end
      attributes
    end

    def get_settings(attributes)
      attributes = attributes.to_a
      settings = {}
      if self.id.nil?
        attributes.each do |field|
          if settings[field.source_type].nil?
            settings[field.source_type] = []
          end
          settings[field.source_type] << ActiveDynamic::FieldSettingsDefinition.new(field_id: field.id, is_visible: true, is_tomstone: false)
        end
      else
        ## TODO need to update for resource
        entity_id = self.id
        entity_name = self.class.name
        if !self.get_dynamic_initializer[:parent_entity].nil?
          entity_id = self.get_dynamic_initializer[:parent_entity].id
          entity_name = self.get_dynamic_initializer[:parent_entity].class.name
        end
        db_settings = ActiveDynamic::Settings.find_by(customizable_id: entity_id, customizable_type: entity_name )
        settings = JSON.parse(db_settings.settings)
        if !self.get_dynamic_initializer[:parent_entity].nil?
          child_settings = settings[self.class.name]
          child_settings.each do |entity|
              attributes << ActiveDynamic::Field.find(entity['field_id']) unless search(attributes, 'id', entity['field_id'])
          end
          settings = child_settings
        else
          settings.each_value do |entity|
            entity.each do |field|
              puts field['field_id']
              attributes << ActiveDynamic::Field.find(field['field_id']) unless search(attributes, 'id', field['field_id'])
             end
          end
        end

      end
      [settings, attributes]
    end

    def get_dynamic_values(attributes)
      values = []
      if self.id.nil?
        attributes.each do |field|
            field = JSON.parse(field.to_json) unless field.class == Hash
            values << ActiveDynamic::FieldValuesDefinition.new(field_id: field['field_id'], field_name: field['field_name'])
         end
      else
        values = []
        db_settings = ActiveDynamic::Values.find_by(customizable_id: self.id, customizable_type: self.class.name)
        if db_settings
          values = JSON.parse(db_settings.values)
        end
        attributes.each do |field|
          field = JSON.parse(field.to_json) unless field.class == Hash
          values << ActiveDynamic::FieldValuesDefinition.new(field_id: field['field_id'], field_name: field['field_name'])  unless search(values, 'field_id', field['field_id'])
        end
      end
      values
    end

    def search(array, key, value)
      array.index {|hash| hash[key] == value}
    end

    def custom

    end

    def generate_accessors(field)
      if field.is_required
        add_presence_validator(field.system_name)
      end


      define_singleton_method(field.system_name) do
        _custom_fields[field.system_name]
      end

      define_singleton_method("#{field.system_name}=") do |value|
        return "Please provide Hash" unless value.class == Hash
        if value[:value].present?
          _custom_fields[field.system_name]['value'] = value[:value].to_s.strip
        end
        if value[:vocab_value].present?
          _custom_fields[field.system_name]['vocab_value'] = value[:vocab_value].to_s.strip
        end
      end
    end

    def add_presence_validator(attribute)
      singleton_class.instance_eval do
        validates_presence_of(attribute)
      end
    end

    def _custom_fields
      @_custom_fields ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def load_dynamic_attributes
      dynamic_attr = dynamic_attributes
      fields = dynamic_attr['fields']
      values = dynamic_attr['values']
      values.each do |ticket_field|
        ticket_field = JSON.parse(ticket_field.to_json) unless ticket_field.class == Hash
        field = ActiveDynamic::Field.find(ticket_field['field_id'])
        _custom_fields[field.system_name] = {value: ticket_field['value'], vocab_value: ticket_field['vocab_value'] }
        generate_accessors field
      end

      # generate_accessors fields
      @dynamic_attributes_loaded = true
    end

    def save_dynamic_attributes
      dynamic_attributes.each do |field|
        next unless _custom_fields[field.name]
        attr = active_dynamic_attributes.find_or_initialize_by(field.as_json)
        if persisted?
          attr.update(value: _custom_fields[field.name])
        else
          attr.assign_attributes(value: _custom_fields[field.name])
        end
      end
    end

    def save_fields
      if self.get_dynamic_initializer[:parent_entity].nil? || (!self.get_dynamic_initializer[:parent_entity].nil? && persisted?)
        fields = dynamic_attributes['fields']
        fields.each do |field|
          if !field.id.nil?
            field.save
          else
            ActiveDynamic::Field.new(field.as_json).save
          end
        end
      end
    end

    def save_settings
      ## TODO: for resource need to update that
      if self.get_dynamic_initializer[:parent_entity].nil?
        @entity_settings = ActiveDynamic::Settings.find_or_initialize_by(customizable_id: self.id, customizable_type: self.class.name)
        @entity_settings.settings = dynamic_attributes['settings'].to_json
      end
    end

    def save_values
      if self.get_dynamic_initializer[:parent_entity].nil? || (!self.get_dynamic_initializer[:parent_entity].nil? && persisted?)
        @entity_values = ActiveDynamic::Values.find_or_initialize_by(customizable_id: self.id, customizable_type: self.class.name)
        values = dynamic_attributes['values']
        latest = []
        values.each do |ticket_field|
          ticket_field = JSON.parse(ticket_field.to_json) unless ticket_field.class == Hash
          field = ActiveDynamic::Field.find(ticket_field['field_id'])
          row = {value: '', vocab_value: ''}
          if !_custom_fields[field.system_name].nil?
            puts  _custom_fields[field.system_name]
            row[:value] = _custom_fields[field.system_name]['value']
            row[:vocab_value] = _custom_fields[field.system_name]['vocab_value']
          end
          row[:field_name] = field.system_name
          row[:field_id] = field.id
          latest << row
        end
        @entity_values.values = latest.to_json
      end

    end

    def update_ids
      if self.get_dynamic_initializer[:parent_entity].nil?
        @entity_settings.customizable_id = self.id
        @entity_settings.save
      end
      if self.get_dynamic_initializer[:parent_entity].nil? || @entity_values.present?
        @entity_values.customizable_id = self.id
        @entity_values.save
      end
    end
  end
end
