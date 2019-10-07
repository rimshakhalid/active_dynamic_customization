class CreateFieldValues < ActiveRecord::Migration[5.1]

  def change
    create_table :field_values do |t|
      t.integer :customizable_id, null: false
      t.string :customizable_type, limit: 50
      t.text :values
      t.timestamps
    end
  end

end
