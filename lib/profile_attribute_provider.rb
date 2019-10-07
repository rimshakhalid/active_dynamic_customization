class ProfileAttributeProvider

  # Constructor will receive an instance to which dynamic attributes are added
  def initialize(model)
    @model = model
  end

  # This method has to return array of dynamic field definitions.
  # You can get it from the configuration file, DB, etc., depending on your app logic
  def call
    case @model
    when Collection
      [
          ActiveDynamic::FieldDefinition.new('identifier', is_vocabulary: 0, column_type: 4, default: 1, help_text:'', source_type: 'Collection' ),
          ActiveDynamic::FieldDefinition.new('creator', is_vocabulary: 0, column_type: 4, default: 1, help_text:'', source_type: 'Collection' ),
          ActiveDynamic::FieldDefinition.new('link', is_vocabulary: 0, column_type: 6, default: 1, help_text:'', source_type: 'Collection' ),
          ActiveDynamic::FieldDefinition.new('date_span', is_vocabulary: 0, column_type: 4, default: 1, help_text:'', source_type: 'Collection'),
          ActiveDynamic::FieldDefinition.new('extent', is_vocabulary: 0, column_type: 4, default: 1, help_text:'', source_type: 'Collection'),
          ActiveDynamic::FieldDefinition.new('language', is_vocabulary: 1, column_type: 1, default: 1, help_text:'', vocabulary: ['English', 'Urdu', 'Punjabi'].to_json, source_type: 'Collection' ),
          ActiveDynamic::FieldDefinition.new('conditions_governing_access', is_vocabulary: 0, column_type: 6, default: 1, help_text:'' , source_type: 'Collection'),
          ActiveDynamic::FieldDefinition.new('title', is_vocabulary: 0, column_type: 4, default: 1, help_text:'', source_type: 'CollectionResource' ),
      ]
    else
      []
    end
  end

end