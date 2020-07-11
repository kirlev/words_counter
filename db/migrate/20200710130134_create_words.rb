class CreateWords < ActiveRecord::Migration[6.0]
  def change
    create_table :words, id: false do |t|
      t.string :name, unique: true, null: false
      t.integer :count, limit: 8, null: false, default: 0
    end

    add_index :words, :name, unique: true
  end
end
