class Collection < ApplicationRecord
  has_many :collection_resources, dependent: :destroy
  has_dynamic_attributes

  attr_accessor :dynamic_initializer
  def get_dynamic_initializer
    @dynamic_initializer = {
        field_types: ['Collection', 'CollectionResource'],
        parent_entity: nil
    }
  end

end
