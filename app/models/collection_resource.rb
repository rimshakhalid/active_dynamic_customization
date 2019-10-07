class CollectionResource < ApplicationRecord
  belongs_to :collection
  has_dynamic_attributes

  attr_accessor :dynamic_initializer
  def get_dynamic_initializer
    @dynamic_initializer = {
        field_types: nil,
        parent_entity: self.collection
    }
  end
end
