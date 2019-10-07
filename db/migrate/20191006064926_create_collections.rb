class CreateCollections < ActiveRecord::Migration[5.1]
  def change
    create_table :collections do |t|
      t.string :title, null: false
      t.text :about
      t.boolean :is_public, default: false
      t.boolean :is_featured, default: false
      t.integer :external_repository_id
      t.text :external_resource_ids
      t.timestamps
    end
  end
end
