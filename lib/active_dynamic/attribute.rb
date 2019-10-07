module ActiveDynamic
  class Attribute < ActiveRecord::Base
    belongs_to :customizable, polymorphic: true

    self.table_name = 'field_values'
    validates :system_name, presence: true
  end

  class Field < ActiveRecord::Base
    self.table_name = 'field_manager'
    validates :system_name, presence: true

    def create(field_obj)
      Field.new(as_json).save
    end
  end

  class Settings < ActiveRecord::Base
    self.table_name = 'field_settings'
  end

  class Values < ActiveRecord::Base
    self.table_name = 'field_values'
  end


end
