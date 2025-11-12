class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.date :date
      t.text :content
      t.integer :humor
      t.string :humor_line
      t.timestamps
    end
  end
end
